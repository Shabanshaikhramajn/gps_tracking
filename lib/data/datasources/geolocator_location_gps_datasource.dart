import 'dart:async';
import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../core/utils/app_logger.dart';
import 'location_gps_datasource.dart';

const String _logTag = 'GeolocatorGps';

// Thrown when real GPS can't be used right now (services disabled,
// permission denied). The UI can catch this; the simulated path is unaffected.
class GpsUnavailableException implements Exception {
  const GpsUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

// Real GPS via geolocator, with background tracking built in via
// platform-specific settings below - see README's background section.
class GeolocatorLocationGpsDataSource implements LocationGpsDataSource {
  StreamSubscription<Position>? _subscription;
  StreamController<LocationFix>? _controller;

  @override
  Stream<LocationFix> start() {
    final StreamController<LocationFix> controller =
        StreamController<LocationFix>.broadcast(onCancel: stop);
    _controller = controller;
    unawaited(_startListening(controller));
    return controller.stream;
  }

  Future<void> _startListening(StreamController<LocationFix> controller) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const GpsUnavailableException(
          'Location services are turned off on this device.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const GpsUnavailableException(
          'Location permission was denied. Enable it in system settings to use real GPS tracking.',
        );
      }
      if (permission == LocationPermission.whileInUse) {
        // Background tracking needs "Always", not just "while in use" -
        // log it so a missing upgrade is visible during testing.
        AppLogger.warning(
          'Only "while in use" location permission is granted; background '
          'tracking will not continue once the app is minimized or the '
          'device is locked until the user grants "Always".',
          name: _logTag,
        );
      }

      // Android 13+ needs this runtime permission or the foreground
      // service's required notification won't actually show.
      if (Platform.isAndroid) {
        final ph.PermissionStatus notificationStatus =
            await ph.Permission.notification.request();
        AppLogger.info(
          'Notification permission status: $notificationStatus.',
          name: _logTag,
        );
      }

      final LocationSettings locationSettings = _buildLocationSettings();
      AppLogger.info('Starting GPS position stream.', name: _logTag);

      _subscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) => controller.add(
          LocationFix(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: position.timestamp ?? DateTime.now(),
            accuracy: position.accuracy,
          ),
        ),
        onError: controller.addError,
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error('Failed to start GPS stream.', name: _logTag, error: error, stackTrace: stackTrace);
      controller.addError(error);
    }
  }

  // Platform-specific location settings - this is where background
  // tracking is actually configured, per platform below.
  LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 5),
        // Runs geolocator's own Android foreground service, which keeps
        // this process alive while the app is backgrounded or locked.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'GPS Tracker is running',
          notificationText: 'Tracking your location in the background.',
          notificationIcon: AndroidResource(
            name: 'mipmap/ic_launcher',
          ),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 5,
        // Keeps updates arriving after the app is backgrounded (needs
        // "Always" permission - see this class's start() method).
        allowBackgroundLocationUpdates: true,
        // Lets iOS pause updates when the device hasn't moved, saving
        // battery, and resume automatically once it moves again.
        pauseLocationUpdatesAutomatically: true,
        // Required blue "using your location" indicator for background use.
        showBackgroundLocationIndicator: true,
      );
    }

    // Any other platform: no background-tracking concept, plain settings.
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  @override
  Future<void> stop() async {
    AppLogger.info('Stopping GPS position stream.', name: _logTag);
    await _subscription?.cancel();
    _subscription = null;
    final StreamController<LocationFix>? controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }
}
