import 'package:flutter/material.dart';

import 'app.dart';
import 'data/datasources/connectivity_datasource.dart';
import 'data/datasources/mock_location_remote_datasource.dart';
import 'data/datasources/simulated_location_gps_datasource.dart';
import 'data/datasources/sqflite_location_local_datasource.dart';
import 'data/repositories/location_repository_impl.dart';
import 'domain/repositories/location_repository.dart';
import 'domain/usecases/initialize_tracking.dart';
import 'domain/usecases/retry_failed_record.dart';
import 'domain/usecases/start_tracking.dart';
import 'domain/usecases/stop_tracking.dart';
import 'domain/usecases/sync_pending_records.dart';
import 'domain/usecases/watch_connectivity_status.dart';
import 'domain/usecases/watch_location_records.dart';
import 'domain/usecases/watch_sync_status.dart';

// Composition root: wires every concrete class together by hand.
// Swap SimulatedLocationGpsDataSource for GeolocatorLocationGpsDataSource for real GPS.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final LocationRepository repository = LocationRepositoryImpl(
    gpsDataSource: SimulatedLocationGpsDataSource(),
    localDataSource: SqfliteLocationLocalDataSource(),
    remoteDataSource: MockLocationRemoteDataSource(),
    connectivityWatcher: ConnectivityPlusWatcher(),
  );

  runApp(
    GpsTrackerApp(
      initializeTracking: InitializeTracking(repository),
      startTracking: StartTracking(repository),
      stopTracking: StopTracking(repository),
      syncPendingRecords: SyncPendingRecords(repository),
      retryFailedRecord: RetryFailedRecord(repository),
      watchLocationRecords: WatchLocationRecords(repository),
      watchSyncStatus: WatchSyncStatus(repository),
      watchConnectivityStatus: WatchConnectivityStatus(repository),
    ),
  );
}
