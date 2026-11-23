// One raw GPS reading: where and when. Deliberately separate from
// LocationRecord, which adds sync bookkeeping (id, status, attempts).
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
}

// Where GPS updates come from while tracking is on. Simulated and real
// (geolocator) implementations are interchangeable behind this interface.
abstract class LocationGpsDataSource {
  // Starts producing fixes. Call stop() before calling start() again.
  Stream<LocationFix> start();

  // Stops producing fixes and releases any underlying subscription.
  Future<void> stop();
}
