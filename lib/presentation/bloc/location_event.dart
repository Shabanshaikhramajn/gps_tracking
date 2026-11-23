part of 'location_bloc.dart';

// Everything LocationBloc can react to: explicit commands (top three)
// and internal stream-driven events (the underscore-prefixed three).
sealed class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

// The user tapped the start/stop tracking button.
class TrackingToggled extends LocationEvent {
  const TrackingToggled();
}

// An explicit sync request. Auto-sync already covers every case the UI
// needs, so no screen dispatches this; kept as part of the event surface.
class SyncRequested extends LocationEvent {
  const SyncRequested();
}

// The user tapped "Retry" on one failed record.
class RecordRetryRequested extends LocationEvent {
  const RecordRetryRequested(this.recordId);

  final String recordId;

  @override
  List<Object?> get props => <Object?>[recordId];
}

// Internal: fires once, right when the bloc is created, to load saved
// records and start listening for connectivity changes.
class _Started extends LocationEvent {
  const _Started();
}

// Internal: the repository's record list changed.
class _RecordsUpdated extends LocationEvent {
  const _RecordsUpdated(this.records);

  final List<LocationRecord> records;

  @override
  List<Object?> get props => <Object?>[records];
}

// Internal: a sync batch started or finished.
class _SyncingStatusChanged extends LocationEvent {
  const _SyncingStatusChanged(this.isSyncing);

  final bool isSyncing;

  @override
  List<Object?> get props => <Object?>[isSyncing];
}

// Internal: the device went online or offline.
class _ConnectivityChanged extends LocationEvent {
  const _ConnectivityChanged(this.isOnline);

  final bool isOnline;

  @override
  List<Object?> get props => <Object?>[isOnline];
}
