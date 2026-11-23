import '../repositories/location_repository.dart';

// Triggers a sync pass over whatever is pending/retryable. Called
// automatically (new fix, connectivity back) - no manual button in the UI.
class SyncPendingRecords {
  SyncPendingRecords(this._repository);

  final LocationRepository _repository;

  Future<void> call() => _repository.syncPending();
}
