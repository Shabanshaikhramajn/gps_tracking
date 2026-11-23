import '../entities/location_record.dart';
import '../repositories/location_repository.dart';

// Exposes the live list of location records as a stream, for the bloc
// to subscribe to.
class WatchLocationRecords {
  WatchLocationRecords(this._repository);

  final LocationRepository _repository;

  Stream<List<LocationRecord>> call() => _repository.watchRecords();
}
