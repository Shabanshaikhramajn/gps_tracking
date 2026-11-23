import '../models/location_record_model.dart';

// Where records persist on-device. The repository only talks to this
// interface, so swapping the real storage for a test double is trivial.
abstract class LocationLocalDataSource {
  // Returns every stored record, oldest first.
  Future<List<LocationRecordModel>> loadAll();

  // Inserts a new record, or replaces the existing one with the same id.
  Future<void> upsertRecord(LocationRecordModel record);
}
