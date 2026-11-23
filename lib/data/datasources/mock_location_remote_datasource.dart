import 'dart:async';
import 'dart:math';

import '../../core/utils/app_logger.dart';
import '../models/location_record_model.dart';
import 'location_remote_datasource.dart';

const String _logTag = 'MockRemote';

// Stands in for a real backend with no network call: simulated latency
// and an occasional failure (both configurable) exercise sync/retry.
class MockLocationRemoteDataSource implements LocationRemoteDataSource {
  MockLocationRemoteDataSource({
    this.latency = const Duration(milliseconds: 600),
    this.failureRate = 0.2,
    Random? random,
  }) : _random = random ?? Random();

  // How long a simulated request takes.
  final Duration latency;

  // 0.0 = always succeeds, 1.0 = always fails.
  final double failureRate;

  final Random _random;

  @override
  Future<SyncAttemptResult> submit(LocationRecordModel record) async {
    await Future<void>.delayed(latency);
    if (_random.nextDouble() < failureRate) {
      AppLogger.debug('Simulated submit failed for record ${record.id}.', name: _logTag);
      return const SyncAttemptResult.failure(
        'Mock backend rejected the request (simulated).',
      );
    }
    AppLogger.debug('Simulated submit succeeded for record ${record.id}.', name: _logTag);
    return const SyncAttemptResult.success();
  }
}
