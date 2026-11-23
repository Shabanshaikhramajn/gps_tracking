import '../repositories/location_repository.dart';

// Exposes whether a sync batch is currently running, as a stream.
class WatchSyncStatus {
  WatchSyncStatus(this._repository);

  final LocationRepository _repository;

  Stream<bool> call() => _repository.watchSyncStatus();
}
