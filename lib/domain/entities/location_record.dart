import 'package:equatable/equatable.dart';

// Where a record stands with the backend: pending (not sent yet),
// synced (confirmed, never resent), or failed (an attempt was rejected).
enum LocationRecordStatus { pending, synced, failed }

// A GPS reading plus sync bookkeeping (status, attempts, last error).
// Knows nothing about SQL/JSON storage - see the data layer's model.
class LocationRecord extends Equatable {
  const LocationRecord({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.accuracy,
    this.status = LocationRecordStatus.pending,
    this.attempts = 0,
    this.lastError,
  });

  // Generated once and never changes; doubles as an idempotency key a
  // real backend can use to reject a duplicate submission.
  final String id;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final double? accuracy;
  final LocationRecordStatus status;

  // Times we've tried sending this record; stops auto-retry after
  // too many failures.
  final int attempts;

  // The error message from the most recent failed attempt, if any.
  final String? lastError;

  bool get isPending => status == LocationRecordStatus.pending;
  bool get isSynced => status == LocationRecordStatus.synced;
  bool get isFailed => status == LocationRecordStatus.failed;

  // Returns a copy with fields replaced; only status, attempts and
  // lastError ever change after creation.
  LocationRecord copyWith({
    LocationRecordStatus? status,
    int? attempts,
    String? lastError,
    bool clearError = false,
  }) {
    return LocationRecord(
      id: id,
      latitude: latitude,
      longitude: longitude,
      capturedAt: capturedAt,
      accuracy: accuracy,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    latitude,
    longitude,
    capturedAt,
    accuracy,
    status,
    attempts,
    lastError,
  ];
}
