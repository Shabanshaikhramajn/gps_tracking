import 'dart:async';
import 'dart:math';

import '../../core/utils/app_logger.dart';
import 'location_gps_datasource.dart';

const String _logTag = 'SimulatedGps';

// A wobbly walking loop around a starting point, one fix every
// [interval]. Needs no permissions - the default source in main.dart.
class SimulatedLocationGpsDataSource implements LocationGpsDataSource {
  SimulatedLocationGpsDataSource({
    this.originLatitude = 25.2048,
    this.originLongitude = 55.2708,
    this.interval = const Duration(seconds: 3),
  });

  // Defaults to a point in Dubai; any starting coordinate works.
  final double originLatitude;
  final double originLongitude;
  final Duration interval;

  Timer? _timer;
  StreamController<LocationFix>? _controller;
  final Random _random = Random();
  int _tick = 0;

  @override
  Stream<LocationFix> start() {
    final StreamController<LocationFix> controller =
        StreamController<LocationFix>.broadcast(onCancel: stop);
    AppLogger.info('Starting simulated GPS stream (every $interval).', name: _logTag);
    _controller = controller;
    _tick = 0;
    _timer = Timer.periodic(interval, (_) => _emitNextFix(controller));
    _emitNextFix(controller); // first fix right away, don't wait a full tick
    return controller.stream;
  }

  void _emitNextFix(StreamController<LocationFix> controller) {
    _tick++;
    // A small wobble so points look like real movement, not a circle.
    final double angle = _tick * 0.35;
    final double wobble = (_random.nextDouble() - 0.5) * 0.0002;
    final double latitude = originLatitude + 0.001 * sin(angle) + wobble;
    final double longitude = originLongitude + 0.001 * cos(angle) + wobble;
    controller.add(
      LocationFix(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 5 + _random.nextDouble() * 10,
      ),
    );
  }

  @override
  Future<void> stop() async {
    AppLogger.info('Stopping simulated GPS stream.', name: _logTag);
    _timer?.cancel();
    _timer = null;
    final StreamController<LocationFix>? controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }
}
