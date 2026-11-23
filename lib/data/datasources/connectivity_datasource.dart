import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/repositories/connectivity_watcher.dart';

// Wraps connectivity_plus behind the domain's ConnectivityWatcher
// contract, so the repository doesn't talk to that package directly.
class ConnectivityPlusWatcher implements ConnectivityWatcher {
  ConnectivityPlusWatcher({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult r) => r != ConnectivityResult.none);

  @override
  Future<bool> get isOnline async =>
      _hasConnection(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection);
}
