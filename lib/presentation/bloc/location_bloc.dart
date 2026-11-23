import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/location_record.dart';
import '../../domain/usecases/initialize_tracking.dart';
import '../../domain/usecases/retry_failed_record.dart';
import '../../domain/usecases/start_tracking.dart';
import '../../domain/usecases/stop_tracking.dart';
import '../../domain/usecases/sync_pending_records.dart';
import '../../domain/usecases/watch_connectivity_status.dart';
import '../../domain/usecases/watch_location_records.dart';
import '../../domain/usecases/watch_sync_status.dart';

part 'location_event.dart';
part 'location_state.dart';

const String _logTag = 'LocationBloc';

// Turns UI taps and repository stream updates into LocationState
// changes; all real logic lives behind the use cases (see test/).
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc({
    required InitializeTracking initializeTracking,
    required StartTracking startTracking,
    required StopTracking stopTracking,
    required SyncPendingRecords syncPendingRecords,
    required RetryFailedRecord retryFailedRecord,
    required WatchLocationRecords watchLocationRecords,
    required WatchSyncStatus watchSyncStatus,
    required WatchConnectivityStatus watchConnectivityStatus,
  }) : _initializeTracking = initializeTracking,
       _startTracking = startTracking,
       _stopTracking = stopTracking,
       _syncPendingRecords = syncPendingRecords,
       _retryFailedRecord = retryFailedRecord,
       super(const LocationState()) {
    on<_Started>(_onStarted);
    on<TrackingToggled>(_onTrackingToggled);
    on<SyncRequested>(_onSyncRequested);
    on<RecordRetryRequested>(_onRecordRetryRequested);
    on<_RecordsUpdated>(_onRecordsUpdated);
    on<_SyncingStatusChanged>(_onSyncingStatusChanged);
    on<_ConnectivityChanged>(_onConnectivityChanged);

    _recordsSubscription = watchLocationRecords().listen(
      (List<LocationRecord> records) => add(_RecordsUpdated(records)),
    );
    _syncingSubscription = watchSyncStatus().listen(
      (bool isSyncing) => add(_SyncingStatusChanged(isSyncing)),
    );
    _connectivitySubscription = watchConnectivityStatus().listen(
      (bool isOnline) => add(_ConnectivityChanged(isOnline)),
    );

    add(const _Started());
  }

  final InitializeTracking _initializeTracking;
  final StartTracking _startTracking;
  final StopTracking _stopTracking;
  final SyncPendingRecords _syncPendingRecords;
  final RetryFailedRecord _retryFailedRecord;

  late final StreamSubscription<List<LocationRecord>> _recordsSubscription;
  late final StreamSubscription<bool> _syncingSubscription;
  late final StreamSubscription<bool> _connectivitySubscription;

  Future<void> _onStarted(_Started event, Emitter<LocationState> emit) async {
    await _initializeTracking();
  }

  Future<void> _onTrackingToggled(
    TrackingToggled event,
    Emitter<LocationState> emit,
  ) async {
    AppLogger.info(
      state.isTracking ? 'UI requested: stop tracking.' : 'UI requested: start tracking.',
      name: _logTag,
    );
    final bool isTracking = state.isTracking
        ? await _stopTracking()
        : await _startTracking();
    emit(state.copyWith(isTracking: isTracking));
  }

  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<LocationState> emit,
  ) async {
    AppLogger.info('UI requested: sync now.', name: _logTag);
    await _syncPendingRecords();
  }

  Future<void> _onRecordRetryRequested(
    RecordRetryRequested event,
    Emitter<LocationState> emit,
  ) async {
    AppLogger.info('UI requested: retry record ${event.recordId}.', name: _logTag);
    await _retryFailedRecord(event.recordId);
  }

  void _onRecordsUpdated(_RecordsUpdated event, Emitter<LocationState> emit) {
    emit(state.copyWith(records: event.records));
  }

  void _onSyncingStatusChanged(
    _SyncingStatusChanged event,
    Emitter<LocationState> emit,
  ) {
    emit(state.copyWith(isSyncing: event.isSyncing));
  }

  void _onConnectivityChanged(
    _ConnectivityChanged event,
    Emitter<LocationState> emit,
  ) {
    emit(state.copyWith(isOnline: event.isOnline));
  }

  @override
  Future<void> close() async {
    AppLogger.info('Bloc closing.', name: _logTag);
    await _recordsSubscription.cancel();
    await _syncingSubscription.cancel();
    await _connectivitySubscription.cancel();
    return super.close();
  }
}
