import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker/app.dart';
import 'package:gps_tracker/data/repositories/location_repository_impl.dart';
import 'package:gps_tracker/domain/repositories/location_repository.dart';
import 'package:gps_tracker/domain/usecases/initialize_tracking.dart';
import 'package:gps_tracker/domain/usecases/retry_failed_record.dart';
import 'package:gps_tracker/domain/usecases/start_tracking.dart';
import 'package:gps_tracker/domain/usecases/stop_tracking.dart';
import 'package:gps_tracker/domain/usecases/sync_pending_records.dart';
import 'package:gps_tracker/domain/usecases/watch_connectivity_status.dart';
import 'package:gps_tracker/domain/usecases/watch_location_records.dart';
import 'package:gps_tracker/domain/usecases/watch_sync_status.dart';

import 'test_support/connectivity_watcher_test_support.dart';
import 'test_support/location_gps_datasource_test_support.dart';
import 'test_support/location_local_datasource_test_support.dart';
import 'test_support/location_remote_datasource_test_support.dart';

void main() {
  testWidgets(
    'GpsTrackerApp renders the tracking page and can start/stop tracking',
    (WidgetTester tester) async {
      final connectivityWatcher = TestConnectivityWatcher(initiallyOnline: true);
      final LocationRepository repository = LocationRepositoryImpl(
        gpsDataSource: TestLocationGpsDataSource(),
        localDataSource: TestLocationLocalDataSource(),
        remoteDataSource: TestLocationRemoteDataSource(),
        connectivityWatcher: connectivityWatcher,
      );

      await tester.pumpWidget(
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
      await tester.pumpAndSettle();

      expect(find.text('GPS Tracker'), findsOneWidget);
      expect(find.text('Start tracking'), findsOneWidget);

      await tester.tap(find.text('Start tracking'));
      await tester.pumpAndSettle();

      expect(find.text('Stop tracking'), findsOneWidget);

      await connectivityWatcher.dispose();
    },
  );
}
