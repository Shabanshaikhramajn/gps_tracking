import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/location_record.dart';
import '../bloc/location_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/last_location_card.dart';
import '../widgets/record_tile.dart';
import '../widgets/status_banner.dart';
import '../widgets/summary_stats_row.dart';

// The one screen, assembled from small reusable widgets (StatusBanner,
// LastLocationCard, SummaryStatsRow, RecordTile, EmptyState).
class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (BuildContext context, LocationState state) {
          return Column(
            children: <Widget>[
              StatusBanner(isOnline: state.isOnline, isSyncing: state.isSyncing),
              LastLocationCard(
                latestRecord: state.records.isEmpty ? null : state.records.last,
                isOnline: state.isOnline,
              ),
              SummaryStatsRow(
                pendingCount: state.pendingCount,
                syncedCount: state.syncedCount,
                failedCount: state.failedCount,
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: state.records.isEmpty
                    ? const EmptyState(
                        message: AppStrings.emptyRecordsMessage,
                        icon: Icons.location_off_outlined,
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: state.records.length,
                        itemBuilder: (BuildContext context, int index) {
                          final LocationRecord record =
                              state.records[state.records.length - 1 - index];
                          return RecordTile(
                            record: record,
                            isOnline: state.isOnline,
                            onRetry: record.isFailed
                                ? () => context.read<LocationBloc>().add(
                                    RecordRetryRequested(record.id),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<LocationBloc, LocationState>(
        builder: (BuildContext context, LocationState state) =>
            FloatingActionButton.extended(
              onPressed: () =>
                  context.read<LocationBloc>().add(const TrackingToggled()),
              icon: Icon(state.isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(
                state.isTracking ? AppStrings.stopTracking : AppStrings.startTracking,
              ),
              backgroundColor: state.isTracking ? AppColors.stopTrackingButton : null,
            ),
      ),
    );
  }
}
