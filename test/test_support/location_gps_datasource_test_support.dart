import 'dart:async';

import 'package:gps_tracker/data/datasources/location_gps_datasource.dart';

// A LocationGpsDataSource the test fully controls: call emit() to push
// a fix whenever the test wants one, instead of waiting on a timer or
// real GPS.
class TestLocationGpsDataSource implements LocationGpsDataSource {
  StreamController<LocationFix>? _controller;

  @override
  Stream<LocationFix> start() {
    final StreamController<LocationFix> controller =
        StreamController<LocationFix>.broadcast();
    _controller = controller;
    return controller.stream;
  }

  void emit(LocationFix fix) => _controller?.add(fix);

  @override
  Future<void> stop() async {
    final StreamController<LocationFix>? controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }
}
