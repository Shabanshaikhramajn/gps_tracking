import 'dart:async';

import 'package:gps_tracker/domain/repositories/connectivity_watcher.dart';

// Lets a test flip "online"/"offline" on demand instead of depending on
// the real device's network state.
class TestConnectivityWatcher implements ConnectivityWatcher {
  TestConnectivityWatcher({bool initiallyOnline = true}) : _online = initiallyOnline;

  bool _online;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isOnline async => _online;

  @override
  Stream<bool> get onStatusChanged => _controller.stream;

  void setOnline(bool online) {
    _online = online;
    _controller.add(online);
  }

  Future<void> dispose() => _controller.close();
}
