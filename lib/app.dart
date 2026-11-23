import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'domain/usecases/initialize_tracking.dart';
import 'domain/usecases/retry_failed_record.dart';
import 'domain/usecases/start_tracking.dart';
import 'domain/usecases/stop_tracking.dart';
import 'domain/usecases/sync_pending_records.dart';
import 'domain/usecases/watch_connectivity_status.dart';
import 'domain/usecases/watch_location_records.dart';
import 'domain/usecases/watch_sync_status.dart';
import 'presentation/bloc/location_bloc.dart';
import 'presentation/pages/tracking_page.dart';
import 'presentation/widgets/app_lifecycle_logger.dart';

// Root widget: builds the LocationBloc from the use cases main.dart
// constructed, wrapped in AppLifecycleLogger for background logging.
class GpsTrackerApp extends StatelessWidget {
  const GpsTrackerApp({
    required this.initializeTracking,
    required this.startTracking,
    required this.stopTracking,
    required this.syncPendingRecords,
    required this.retryFailedRecord,
    required this.watchLocationRecords,
    required this.watchSyncStatus,
    required this.watchConnectivityStatus,
    super.key,
  });

  final InitializeTracking initializeTracking;
  final StartTracking startTracking;
  final StopTracking stopTracking;
  final SyncPendingRecords syncPendingRecords;
  final RetryFailedRecord retryFailedRecord;
  final WatchLocationRecords watchLocationRecords;
  final WatchSyncStatus watchSyncStatus;
  final WatchConnectivityStatus watchConnectivityStatus;

  @override
  Widget build(BuildContext context) {
    return AppLifecycleLogger(
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed),
          useMaterial3: true,
        ),
        home: BlocProvider<LocationBloc>(
          create: (_) => LocationBloc(
            initializeTracking: initializeTracking,
            startTracking: startTracking,
            stopTracking: stopTracking,
            syncPendingRecords: syncPendingRecords,
            retryFailedRecord: retryFailedRecord,
            watchLocationRecords: watchLocationRecords,
            watchSyncStatus: watchSyncStatus,
            watchConnectivityStatus: watchConnectivityStatus,
          ),
          child: const TrackingPage(),
        ),
      ),
    );
  }
}
