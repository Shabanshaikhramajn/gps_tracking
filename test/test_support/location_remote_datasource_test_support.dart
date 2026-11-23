import 'package:gps_tracker/data/datasources/location_remote_datasource.dart';
import 'package:gps_tracker/data/models/location_record_model.dart';

// Deterministic stand-in for the backend: outcomes are queued up by the
// test via enqueueSuccess()/enqueueFailure() and consumed one per
// submit() call, falling back to [defaultSucceeds] once the queue runs
// out. Also records every id it was asked to submit, so a test can
// assert a synced record is never sent again.
class TestLocationRemoteDataSource implements LocationRemoteDataSource {
  TestLocationRemoteDataSource({this.defaultSucceeds = true});

  final bool defaultSucceeds;
  final List<String> submittedIds = <String>[];
  final List<bool> _queue = <bool>[];

  void enqueueSuccess() => _queue.add(true);
  void enqueueFailure() => _queue.add(false);

  @override
  Future<SyncAttemptResult> submit(LocationRecordModel record) async {
    submittedIds.add(record.id);
    final bool succeeds = _queue.isNotEmpty ? _queue.removeAt(0) : defaultSucceeds;
    return succeeds
        ? const SyncAttemptResult.success()
        : const SyncAttemptResult.failure('Simulated failure for test.');
  }
}
