import '../entities/location_record.dart';

// The one contract the app uses for location data; presentation never
// sees sqflite/geolocator directly. LocationRepositoryImpl holds the rules.
abstract class LocationRepository {
  // Loads whatever was saved from a previous run and starts listening
  // for connectivity changes. Must be called once before anything else.
  Future<void> initialize();

  // Emits the full list of records every time something about it changes
  // (a new fix captured, a sync attempt finishing, a retry).
  Stream<List<LocationRecord>> watchRecords();

  // Emits true while a sync batch is in progress, false once it finishes.
  Stream<bool> watchSyncStatus();

  // Emits the device's online/offline status as it changes.
  Stream<bool> watchConnectivity();

  // Whether GPS capture is currently running.
  bool get isTracking;

  // Starts producing location fixes (real or simulated GPS, depending on
  // which implementation was wired up) and storing each one locally.
  Future<void> startTracking();

  // Stops producing new fixes. Already-stored records are left as-is.
  Future<void> stopTracking();

  // Sends every pending/retryable record to the backend, skipping
  // anything already synced and refusing to run twice at once.
  Future<void> syncPending();

  // Resends one specific record by id, regardless of how many times it
  // has already failed - this is what a manual "Retry" button calls.
  Future<void> retryRecord(String id);

  // Releases streams/subscriptions. Call when the repository is no
  // longer needed (e.g. the app is shutting down).
  Future<void> dispose();
}
