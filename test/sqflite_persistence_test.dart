import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker/data/datasources/location_gps_datasource.dart';
import 'package:gps_tracker/data/datasources/sqflite_location_local_datasource.dart';
import 'package:gps_tracker/data/models/location_record_model.dart';
import 'package:gps_tracker/data/repositories/location_repository_impl.dart';
import 'package:gps_tracker/domain/entities/location_record.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_support/connectivity_watcher_test_support.dart';
import 'test_support/location_gps_datasource_test_support.dart';
import 'test_support/location_remote_datasource_test_support.dart';

// Tests against a real on-disk SQLite file (sqflite_common_ffi), proving
// restart persistence and sync recovery - not the in-memory fake. Kept in
// one file since every test shares the same hardcoded db file.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<String> databaseFilePath() async {
    final String databasesPath = await getDatabasesPath();
    return p.join(databasesPath, 'gps_tracker.db');
  }

  // Start every test from an empty db file so runs don't leak into each
  // other or inherit stale rows from a previous failure.
  setUp(() async {
    await deleteDatabase(await databaseFilePath());
  });

  // "Restart" = write, explicitly close the connection, then reopen a
  // fresh instance on the same file - closing matters since sqflite's
  // singleInstance default would otherwise just reuse the open connection.
  Future<void> closeSharedDatabase() async {
    final Database db = await openDatabase(await databaseFilePath());
    await db.close();
  }

  group('SqfliteLocationLocalDataSource (real SQLite file)', () {
    LocationRecordModel sampleRecord({
      String id = 'record-1',
      LocationRecordStatus status = LocationRecordStatus.pending,
      int attempts = 0,
    }) {
      return LocationRecordModel(
        id: id,
        latitude: 12.34,
        longitude: 56.78,
        capturedAt: DateTime.utc(2026, 1, 1, 9, 30),
        accuracy: 5.5,
        status: status,
        attempts: attempts,
      );
    }

    test('a record written in one session is still there after a restart', () async {
      final SqfliteLocationLocalDataSource writer = SqfliteLocationLocalDataSource();
      await writer.upsertRecord(sampleRecord());
      await closeSharedDatabase();

      final SqfliteLocationLocalDataSource afterRestart = SqfliteLocationLocalDataSource();
      final records = await afterRestart.loadAll();

      expect(records, hasLength(1));
      expect(records.single.id, 'record-1');
      expect(records.single.latitude, 12.34);
      expect(records.single.longitude, 56.78);
      expect(records.single.accuracy, 5.5);
      expect(records.single.isPending, isTrue);
    });

    test('status and attempts survive a restart too, not just the coordinates', () async {
      final SqfliteLocationLocalDataSource writer = SqfliteLocationLocalDataSource();
      await writer.upsertRecord(
        sampleRecord(status: LocationRecordStatus.failed, attempts: 3),
      );
      await closeSharedDatabase();

      final SqfliteLocationLocalDataSource afterRestart = SqfliteLocationLocalDataSource();
      final records = await afterRestart.loadAll();

      expect(records.single.isFailed, isTrue);
      expect(records.single.attempts, 3);
    });

    test('upserting the same id replaces the row instead of duplicating it', () async {
      final SqfliteLocationLocalDataSource datasource = SqfliteLocationLocalDataSource();
      await datasource.upsertRecord(sampleRecord());
      await datasource.upsertRecord(
        sampleRecord(status: LocationRecordStatus.failed, attempts: 1),
      );
      await closeSharedDatabase();

      final SqfliteLocationLocalDataSource afterRestart = SqfliteLocationLocalDataSource();
      final records = await afterRestart.loadAll();

      expect(
        records,
        hasLength(1),
        reason: 'retrying/updating a record must replace its row, never add a second one',
      );
      expect(records.single.isFailed, isTrue);
      expect(records.single.attempts, 1);
    });

    test('multiple records all persist and reload oldest-captured first', () async {
      final SqfliteLocationLocalDataSource writer = SqfliteLocationLocalDataSource();
      await writer.upsertRecord(
        LocationRecordModel(
          id: 'b',
          latitude: 2,
          longitude: 2,
          capturedAt: DateTime.utc(2026, 1, 1, 10),
        ),
      );
      await writer.upsertRecord(
        LocationRecordModel(
          id: 'a',
          latitude: 1,
          longitude: 1,
          capturedAt: DateTime.utc(2026, 1, 1, 9),
        ),
      );
      await closeSharedDatabase();

      final SqfliteLocationLocalDataSource afterRestart = SqfliteLocationLocalDataSource();
      final records = await afterRestart.loadAll();

      expect(records.map((LocationRecordModel r) => r.id).toList(), <String>['a', 'b']);
    });
  });

  group('LocationRepositoryImpl + real SQLite', () {
    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

    test(
      'a record that failed to sync before restart is retried and synced after it',
      () async {
        // "Session 1": online, but the backend rejects this attempt,
        // so the record ends up stored as failed.
        final TestLocationGpsDataSource gpsDataSource1 = TestLocationGpsDataSource();
        final TestLocationRemoteDataSource remoteDataSource1 =
            TestLocationRemoteDataSource()..enqueueFailure();
        final TestConnectivityWatcher connectivityWatcher1 =
            TestConnectivityWatcher(initiallyOnline: true);
        final LocationRepositoryImpl repository1 = LocationRepositoryImpl(
          gpsDataSource: gpsDataSource1,
          localDataSource: SqfliteLocationLocalDataSource(),
          remoteDataSource: remoteDataSource1,
          connectivityWatcher: connectivityWatcher1,
        );

        await repository1.initialize();
        await repository1.startTracking();
        gpsDataSource1.emit(
          LocationFix(latitude: 10, longitude: 20, timestamp: DateTime.utc(2026)),
        );
        await settle();
        await repository1.dispose();
        await connectivityWatcher1.dispose();

        // Confirm the failure landed in the real database before moving
        // on, so recovery below is proven, not just a record that was
        // already fine.
        final SqfliteLocationLocalDataSource midCheck = SqfliteLocationLocalDataSource();
        final midRecords = await midCheck.loadAll();
        expect(midRecords.single.isFailed, isTrue);
        expect(midRecords.single.attempts, 1);

        // "Restart": close the leftover connection, then build a brand
        // new repository against the same db file.
        await closeSharedDatabase();

        final TestLocationGpsDataSource gpsDataSource2 = TestLocationGpsDataSource();
        final TestLocationRemoteDataSource remoteDataSource2 =
            TestLocationRemoteDataSource(); // defaults to success this time
        final TestConnectivityWatcher connectivityWatcher2 =
            TestConnectivityWatcher(initiallyOnline: true);
        final LocationRepositoryImpl repository2 = LocationRepositoryImpl(
          gpsDataSource: gpsDataSource2,
          localDataSource: SqfliteLocationLocalDataSource(),
          remoteDataSource: remoteDataSource2,
          connectivityWatcher: connectivityWatcher2,
        );

        final List<dynamic> recordsAfterRestart = <dynamic>[];
        final subscription = repository2.watchRecords().listen(recordsAfterRestart.add);

        // initialize() runs on every launch: reload the failed record
        // and, since we're online, resync it automatically.
        await repository2.initialize();
        await settle();

        expect(
          remoteDataSource2.submittedIds,
          hasLength(1),
          reason: 'the record saved before restart must actually be resubmitted, '
              'not just reloaded and left sitting as failed',
        );
        expect(
          recordsAfterRestart.last.single.isSynced,
          isTrue,
          reason: 'it should end up synced once the resubmit succeeds',
        );

        final SqfliteLocationLocalDataSource finalCheck = SqfliteLocationLocalDataSource();
        final finalRecords = await finalCheck.loadAll();
        expect(
          finalRecords.single.isSynced,
          isTrue,
          reason: 'the synced status must itself be persisted, not just emitted on the stream',
        );

        await subscription.cancel();
        await repository2.dispose();
        await connectivityWatcher2.dispose();
      },
    );
  });
}
