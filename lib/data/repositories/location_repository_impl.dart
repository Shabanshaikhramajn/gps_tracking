import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/location_record.dart';
import '../../domain/repositories/connectivity_watcher.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_gps_datasource.dart';
import '../datasources/location_local_datasource.dart';
import '../datasources/location_remote_datasource.dart';
import '../models/location_record_model.dart';

const String _logTag = 'LocationRepository';

// Wires GPS capture, storage, backend and connectivity together:
// offline-first, auto-sync, no duplicate sends, retry with a cap.
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl({
    required LocationGpsDataSource gpsDataSource,
    required LocationLocalDataSource localDataSource,
    required LocationRemoteDataSource remoteDataSource,
    required ConnectivityWatcher connectivityWatcher,
    this.maxAutoRetryAttempts = 5,
    Uuid? uuid,
  }) : _gpsDataSource = gpsDataSource,
       _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _connectivityWatcher = connectivityWatcher,
       _uuid = uuid ?? const Uuid();

  final LocationGpsDataSource _gpsDataSource;
  final LocationLocalDataSource _localDataSource;
  final LocationRemoteDataSource _remoteDataSource;
  final ConnectivityWatcher _connectivityWatcher;
  final Uuid _uuid;

  // After this many failures a record stops auto-retrying, but stays
  // retryable by hand via retryRecord().
  final int maxAutoRetryAttempts;

  final StreamController<List<LocationRecord>> _recordsController =
      StreamController<List<LocationRecord>>.broadcast();
  final StreamController<bool> _syncingController =
      StreamController<bool>.broadcast();

  // In-memory mirror of the database, loaded once in initialize() and
  // kept in sync on every write after that.
  final List<LocationRecordModel> _records = <LocationRecordModel>[];

  StreamSubscription<LocationFix>? _fixSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isTracking = false;
  bool _isSyncing = false;
  bool _initialized = false;

  @override
  Stream<List<LocationRecord>> watchRecords() => _recordsController.stream;

  @override
  Stream<bool> watchSyncStatus() => _syncingController.stream;

  @override
  Stream<bool> watchConnectivity() => _connectivityWatcher.onStatusChanged;

  @override
  bool get isTracking => _isTracking;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    AppLogger.info('Initializing repository.', name: _logTag);

    final List<LocationRecordModel> stored = await _localDataSource.loadAll();
    _records.addAll(stored);
    _emitRecords();
    AppLogger.info('Loaded ${stored.length} record(s) from local storage.', name: _logTag);

    // Sync automatically once connectivity returns.
    _connectivitySubscription = _connectivityWatcher.onStatusChanged.listen((
      bool online,
    ) {
      AppLogger.info('Connectivity changed: ${online ? 'online' : 'offline'}.', name: _logTag);
      if (online) {
        unawaited(syncPending());
      }
    });

    // Also try once at startup in case we're already online.
    if (await _connectivityWatcher.isOnline) {
      unawaited(syncPending());
    }
  }

  @override
  Future<void> startTracking() async {
    if (_isTracking) {
      return;
    }
    _isTracking = true;
    AppLogger.info('Tracking started.', name: _logTag);
    _fixSubscription = _gpsDataSource.start().listen(
      _onFix,
      onError: (Object error, StackTrace stackTrace) {
        // Stop cleanly on a GPS error instead of staying "on" with no
        // new fixes arriving.
        AppLogger.error('GPS stream error, stopping tracking.', name: _logTag, error: error, stackTrace: stackTrace);
        unawaited(stopTracking());
      },
    );
  }

  @override
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return;
    }
    _isTracking = false;
    AppLogger.info('Tracking stopped.', name: _logTag);
    await _fixSubscription?.cancel();
    _fixSubscription = null;
    await _gpsDataSource.stop();
  }

  // Saves every fix locally first, online or not, then tries to sync.
  Future<void> _onFix(LocationFix fix) async {
    final LocationRecordModel record = LocationRecordModel(
      id: _uuid.v4(),
      latitude: fix.latitude,
      longitude: fix.longitude,
      capturedAt: fix.timestamp,
      accuracy: fix.accuracy,
    );
    _records.add(record);
    await _localDataSource.upsertRecord(record);
    _emitRecords();
    AppLogger.debug(
      'Fix captured: ${record.latitude.toStringAsFixed(5)}, '
      '${record.longitude.toStringAsFixed(5)} (id: ${record.id}).',
      name: _logTag,
    );

    if (await _connectivityWatcher.isOnline) {
      unawaited(syncPending());
    }
  }

  @override
  Future<void> syncPending() async {
    if (_isSyncing) {
      // Already running (a previous fix or connectivity event) -
      // a second call is a no-op, not a second batch.
      AppLogger.debug('Sync already in progress, ignoring this trigger.', name: _logTag);
      return;
    }
    final List<LocationRecordModel> eligible = _records
        .where((LocationRecordModel r) => !r.isSynced && r.attempts < maxAutoRetryAttempts)
        .toList();
    if (eligible.isEmpty) {
      return;
    }
    AppLogger.info('Starting sync of ${eligible.length} record(s).', name: _logTag);
    _isSyncing = true;
    _setSyncing(true);
    try {
      for (final LocationRecordModel record in eligible) {
        await _submitOne(record);
      }
    } finally {
      _isSyncing = false;
      _setSyncing(false);
      AppLogger.info('Sync batch finished.', name: _logTag);
    }
  }

  @override
  Future<void> retryRecord(String id) async {
    if (_isSyncing) {
      // Don't race a manual retry against a batch sync.
      AppLogger.debug('Retry requested for $id while a sync is already running; ignoring.', name: _logTag);
      return;
    }
    final int index = _records.indexWhere((LocationRecordModel r) => r.id == id);
    if (index == -1 || _records[index].isSynced) {
      return;
    }
    AppLogger.info('Manual retry requested for record $id.', name: _logTag);
    await _submitOne(_records[index]);
  }

  // Submits one record and records the outcome - the only place that
  // calls the remote datasource, for both auto-sync and manual retry.
  Future<void> _submitOne(LocationRecordModel record) async {
    final SyncAttemptResult result = await _remoteDataSource.submit(record);

    final int index = _records.indexWhere((LocationRecordModel r) => r.id == record.id);
    if (index == -1) {
      return; // record was removed from under us; nothing left to update.
    }

    final LocationRecordModel current = _records[index];
    final LocationRecord updatedEntity = result.isSuccess
        ? current.copyWith(status: LocationRecordStatus.synced, clearError: true)
        : current.copyWith(
            status: LocationRecordStatus.failed,
            attempts: current.attempts + 1,
            lastError: result.error,
          );
    final LocationRecordModel updated = LocationRecordModel.fromEntity(updatedEntity);

    if (result.isSuccess) {
      AppLogger.info('Record ${record.id} synced successfully.', name: _logTag);
    } else {
      AppLogger.warning(
        'Record ${record.id} failed to sync (attempt ${updated.attempts}): ${result.error}',
        name: _logTag,
      );
    }

    _records[index] = updated;
    await _localDataSource.upsertRecord(updated);
    _emitRecords();
  }

  void _emitRecords() {
    if (!_recordsController.isClosed) {
      _recordsController.add(List<LocationRecord>.of(_records));
    }
  }

  void _setSyncing(bool value) {
    if (!_syncingController.isClosed) {
      _syncingController.add(value);
    }
  }

  @override
  Future<void> dispose() async {
    AppLogger.info('Disposing repository.', name: _logTag);
    await _fixSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    await _gpsDataSource.stop();
    await _recordsController.close();
    await _syncingController.close();
  }
}
