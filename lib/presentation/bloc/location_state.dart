part of 'location_bloc.dart';

// Everything the UI needs for one frame: tracking/syncing/online flags
// and the record list. The count getters feed the summary row.
class LocationState extends Equatable {
  const LocationState({
    this.isTracking = false,
    this.isSyncing = false,
    this.isOnline = true,
    this.records = const <LocationRecord>[],
  });

  final bool isTracking;
  final bool isSyncing;
  final bool isOnline;
  final List<LocationRecord> records;

  int get pendingCount =>
      records.where((LocationRecord r) => r.isPending).length;
  int get syncedCount =>
      records.where((LocationRecord r) => r.isSynced).length;
  int get failedCount =>
      records.where((LocationRecord r) => r.isFailed).length;

  LocationState copyWith({
    bool? isTracking,
    bool? isSyncing,
    bool? isOnline,
    List<LocationRecord>? records,
  }) {
    return LocationState(
      isTracking: isTracking ?? this.isTracking,
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      records: records ?? this.records,
    );
  }

  @override
  List<Object?> get props => <Object?>[isTracking, isSyncing, isOnline, records];
}
