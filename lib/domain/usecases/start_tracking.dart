import '../repositories/location_repository.dart';

// Starts GPS capture. Returns the resulting tracking state so callers
// (the bloc) don't need a second round trip just to read it back.
class StartTracking {
  StartTracking(this._repository);

  final LocationRepository _repository;

  Future<bool> call() async {
    await _repository.startTracking();
    return _repository.isTracking;
  }
}
