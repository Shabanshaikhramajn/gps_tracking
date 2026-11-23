import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker/data/datasources/location_gps_datasource.dart';
import 'package:gps_tracker/data/repositories/location_repository_impl.dart';

import 'test_support/connectivity_watcher_test_support.dart';
import 'test_support/location_gps_datasource_test_support.dart';
import 'test_support/location_local_datasource_test_support.dart';
import 'test_support/location_remote_datasource_test_support.dart';

// Automated tests for offline storage, automatic sync on connectivity
// return, and retry handling. Everything runs against
// LocationRepositoryImpl directly, with every dependency swapped for an
// in-memory test double (test/test_support/), so these tests are
// deterministic and need no device, network, or Flutter widget tree at
// all.
void main() {
  late TestLocationGpsDataSource gpsDataSource;
  late TestLocationLocalDataSource localDataSource;
  late TestLocationRemoteDataSource remoteDataSource;
  late TestConnectivityWatcher connectivityWatcher;
  late LocationRepositoryImpl repository;

  setUp(() {
    gpsDataSource = TestLocationGpsDataSource();
    localDataSource = TestLocationLocalDataSource();
    remoteDataSource = TestLocationRemoteDataSource();
    connectivityWatcher = TestConnectivityWatcher(initiallyOnline: false);
    repository = LocationRepositoryImpl(
      gpsDataSource: gpsDataSource,
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      connectivityWatcher: connectivityWatcher,
    );
  });

  tearDown(() async {
    await repository.dispose();
    await connectivityWatcher.dispose();
  });

  LocationFix sampleFix() =>
      LocationFix(latitude: 1, longitude: 2, timestamp: DateTime(2026));

  // Lets any already-queued microtasks (our test doubles have no real delay)
  // finish before the test checks the result of something fired with
  // unawaited(), such as the automatic sync triggered after a fix.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

  test('captured fixes are stored locally while offline and stay pending', () async {
    await repository.initialize();
    await repository.startTracking();

    gpsDataSource.emit(sampleFix());
    await settle();

    // Checking the local data source directly (rather than the live
    // stream) is deliberate: watchRecords() is a broadcast stream and
    // only delivers events to listeners from the moment they subscribe,
    // so reading .first here could wait forever for an update that
    // already happened before we started listening. Reading back what
    // was actually saved is the more direct, reliable check anyway.
    final records = await localDataSource.loadAll();
    expect(records, hasLength(1));
    expect(records.single.isPending, isTrue);
    expect(
      remoteDataSource.submittedIds,
      isEmpty,
      reason: 'nothing should be sent to the backend while offline',
    );
    expect(
      localDataSource.upsertCount,
      greaterThan(0),
      reason: 'the record must be persisted locally',
    );
  });

  test('pending records sync automatically once connectivity returns', () async {
    await repository.initialize();
    await repository.startTracking();
    gpsDataSource.emit(sampleFix());
    await settle();

    List<dynamic> records = await localDataSource.loadAll();
    expect(records.single.isPending, isTrue);

    connectivityWatcher.setOnline(true);
    await settle();

    records = await localDataSource.loadAll();
    expect(records.single.isSynced, isTrue);
    expect(remoteDataSource.submittedIds, hasLength(1));
  });

  test('a synced record is never submitted again', () async {
    connectivityWatcher.setOnline(true);
    await repository.initialize();
    await repository.startTracking();
    gpsDataSource.emit(sampleFix());
    await settle();

    var records = await localDataSource.loadAll();
    expect(records.single.isSynced, isTrue);

    // Triggering sync again - as a second connectivity event would -
    // must not resend the same record.
    await repository.syncPending();
    await repository.syncPending();

    expect(remoteDataSource.submittedIds, hasLength(1));
  });

  test('overlapping sync triggers do not double-submit the same batch', () async {
    await repository.initialize(); // stays offline: connectivityWatcher defaults to false
    await repository.startTracking();
    gpsDataSource.emit(sampleFix());
    await settle();

    var records = await localDataSource.loadAll();
    expect(records.single.isPending, isTrue);

    // Two triggers racing (e.g. a connectivity event and a manual "Sync
    // now" tap landing at once) must not send the same record twice -
    // the in-flight guard should make the second call a no-op.
    final first = repository.syncPending();
    final second = repository.syncPending();
    await Future.wait([first, second]);

    expect(remoteDataSource.submittedIds, hasLength(1));
    records = await localDataSource.loadAll();
    expect(records.single.isSynced, isTrue);
  });

  test('a failed sync is retried and marked synced once it succeeds', () async {
    remoteDataSource.enqueueFailure();
    connectivityWatcher.setOnline(true);
    await repository.initialize();
    await repository.startTracking();
    gpsDataSource.emit(sampleFix());
    await settle();

    var records = await localDataSource.loadAll();
    expect(records.single.isFailed, isTrue);
    expect(records.single.attempts, 1);

    await repository.retryRecord(records.single.id);

    records = await localDataSource.loadAll();
    expect(records.single.isSynced, isTrue);
    expect(
      remoteDataSource.submittedIds,
      hasLength(2),
      reason: 'one failed attempt, then one successful retry',
    );
  });

  test(
    'a record that exhausts its automatic retries stops being auto-synced',
    () async {
      connectivityWatcher.setOnline(true);
      remoteDataSource
        ..enqueueFailure() // consumed by the automatic attempt right after capture
        ..enqueueFailure(); // consumed by the next explicit sync
      repository = LocationRepositoryImpl(
        gpsDataSource: gpsDataSource,
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityWatcher: connectivityWatcher,
        maxAutoRetryAttempts: 2,
      );
      await repository.initialize();
      await repository.startTracking();
      gpsDataSource.emit(sampleFix());
      await settle();

      await repository.syncPending();
      await settle();

      var records = await localDataSource.loadAll();
      expect(records.single.isFailed, isTrue);
      expect(records.single.attempts, 2);

      final int submittedBefore = remoteDataSource.submittedIds.length;
      await repository.syncPending(); // cap reached -- must be a no-op now
      expect(remoteDataSource.submittedIds.length, submittedBefore);
    },
  );
}
