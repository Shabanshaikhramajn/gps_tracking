import '../repositories/location_repository.dart';

// Exposes the device's online/offline status, as a stream.
class WatchConnectivityStatus {
  WatchConnectivityStatus(this._repository);

  final LocationRepository _repository;

  Stream<bool> call() => _repository.watchConnectivity();
}
