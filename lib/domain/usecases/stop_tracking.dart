import '../repositories/location_repository.dart';

// Stops GPS capture. Returns the resulting tracking state, same reason
// as StartTracking.
class StopTracking {
  StopTracking(this._repository);

  final LocationRepository _repository;

  Future<bool> call() async {
    await _repository.stopTracking();
    return _repository.isTracking;
  }
}
