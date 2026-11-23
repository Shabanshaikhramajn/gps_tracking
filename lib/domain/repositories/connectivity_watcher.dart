// Whether the device has *some* network path - not proof the backend
// is reachable. The real connectivity_plus-backed impl lives in data/.
abstract class ConnectivityWatcher {
  Future<bool> get isOnline;
  Stream<bool> get onStatusChanged;
}
