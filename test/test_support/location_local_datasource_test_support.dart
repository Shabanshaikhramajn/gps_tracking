import 'package:gps_tracker/data/datasources/location_local_datasource.dart';
import 'package:gps_tracker/data/models/location_record_model.dart';

// Keeps records purely in memory for the duration of a test - exercises
// LocationRepositoryImpl's persistence calls without touching SQLite.
class TestLocationLocalDataSource implements LocationLocalDataSource {
  final Map<String, LocationRecordModel> _stored = <String, LocationRecordModel>{};
  int upsertCount = 0;

  @override
  Future<List<LocationRecordModel>> loadAll() async => _stored.values.toList();

  @override
  Future<void> upsertRecord(LocationRecordModel record) async {
    _stored[record.id] = record;
    upsertCount++;
  }
}
