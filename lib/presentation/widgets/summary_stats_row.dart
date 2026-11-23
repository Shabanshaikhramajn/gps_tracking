import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'stat_chip.dart';

// The row of pending/synced/failed counts. Sync is automatic (see
// LocationRepositoryImpl); StatusBanner above shows when it's running.
class SummaryStatsRow extends StatelessWidget {
  const SummaryStatsRow({
    required this.pendingCount,
    required this.syncedCount,
    required this.failedCount,
    super.key,
  });

  final int pendingCount;
  final int syncedCount;
  final int failedCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          StatChip(
            label: AppStrings.pendingLabel,
            value: pendingCount,
            color: AppColors.pending,
          ),
          StatChip(
            label: AppStrings.syncedLabel,
            value: syncedCount,
            color: AppColors.synced,
          ),
          StatChip(
            label: AppStrings.failedLabel,
            value: failedCount,
            color: AppColors.failed,
          ),
        ],
      ),
    );
  }
}
