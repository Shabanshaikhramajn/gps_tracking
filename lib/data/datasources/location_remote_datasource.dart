import '../models/location_record_model.dart';

// What the backend reported for one sync attempt.
class SyncAttemptResult {
  const SyncAttemptResult.success() : error = null, isSuccess = true;
  const SyncAttemptResult.failure(this.error) : isSuccess = false;

  final bool isSuccess;
  final String? error;
}

// Sends one already-captured record to the backend. A single method so
// any backend - real, mock, or a test double - can stand in for another.
abstract class LocationRemoteDataSource {
  Future<SyncAttemptResult> submit(LocationRecordModel record);
}
