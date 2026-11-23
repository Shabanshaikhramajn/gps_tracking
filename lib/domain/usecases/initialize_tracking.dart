import '../repositories/location_repository.dart';

// Loads previously saved records and starts listening for connectivity
// changes. Run once, right when the app starts.
class InitializeTracking {
  InitializeTracking(this._repository);

  final LocationRepository _repository;

  Future<void> call() => _repository.initialize();
}
