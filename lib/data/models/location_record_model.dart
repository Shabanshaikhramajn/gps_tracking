import '../../domain/entities/location_record.dart';

// Data-layer version of LocationRecord, adding to/from-database-row
// conversions so the domain entity stays free of storage details.
class LocationRecordModel extends LocationRecord {
  const LocationRecordModel({
    required super.id,
    required super.latitude,
    required super.longitude,
    required super.capturedAt,
    super.accuracy,
    super.status,
    super.attempts,
    super.lastError,
  });

  // Wraps a plain entity as a model, for handing to the local datasource.
  factory LocationRecordModel.fromEntity(LocationRecord entity) {
    return LocationRecordModel(
      id: entity.id,
      latitude: entity.latitude,
      longitude: entity.longitude,
      capturedAt: entity.capturedAt,
      accuracy: entity.accuracy,
      status: entity.status,
      attempts: entity.attempts,
      lastError: entity.lastError,
    );
  }

  // Builds a model from one row of the location_records table.
  factory LocationRecordModel.fromMap(Map<String, Object?> map) {
    return LocationRecordModel(
      id: map['id'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      capturedAt: DateTime.parse(map['capturedAt'] as String),
      accuracy: map['accuracy'] as double?,
      status: LocationRecordStatus.values.byName(map['status'] as String),
      attempts: map['attempts'] as int,
      lastError: map['lastError'] as String?,
    );
  }

  // A row ready for sqflite's insert/update calls (dates as ISO-8601
  // text, the enum as its name - SQLite has neither type natively).
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'capturedAt': capturedAt.toIso8601String(),
      'accuracy': accuracy,
      'status': status.name,
      'attempts': attempts,
      'lastError': lastError,
    };
  }
}
