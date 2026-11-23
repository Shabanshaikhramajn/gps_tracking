import '../repositories/location_repository.dart';

// Resends one record by id. This is what the "Retry" button on a
// failed record calls.
class RetryFailedRecord {
  RetryFailedRecord(this._repository);

  final LocationRepository _repository;

  Future<void> call(String recordId) => _repository.retryRecord(recordId);
}
