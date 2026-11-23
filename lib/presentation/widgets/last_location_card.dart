import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/time_format.dart';
import '../../domain/entities/location_record.dart';

// Shows the most recent fix with a plain-English sync status.
// [isOnline] only affects the wording for a still-pending fix.
class LastLocationCard extends StatelessWidget {
  const LastLocationCard({
    required this.latestRecord,
    required this.isOnline,
    super.key,
  });

  final LocationRecord? latestRecord;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final LocationRecord? record = latestRecord;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: record == null ? _buildEmpty(context) : _buildRecord(context, record),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.location_searching, color: AppColors.emptyStateIcon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppStrings.noLocationYetMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildRecord(BuildContext context, LocationRecord record) {
    final Color statusColor = _statusColor(record);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppStrings.lastLocationTitle,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 4),
        Text(
          '${record.latitude.toStringAsFixed(5)}, ${record.longitude.toStringAsFixed(5)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Icon(_statusIcon(record), size: 16, color: statusColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _statusLabel(record),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${TimeFormat.clock(record.capturedAt)} (${TimeFormat.relative(record.capturedAt)})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  IconData _statusIcon(LocationRecord record) {
    if (record.isSynced) {
      return Icons.cloud_done;
    }
    if (record.isFailed) {
      return Icons.cloud_off;
    }
    return isOnline ? Icons.cloud_upload : Icons.save_outlined;
  }

  Color _statusColor(LocationRecord record) {
    if (record.isSynced) {
      return AppColors.synced;
    }
    if (record.isFailed) {
      return AppColors.failed;
    }
    return isOnline ? AppColors.syncing : AppColors.pending;
  }

  String _statusLabel(LocationRecord record) {
    if (record.isSynced) {
      return AppStrings.syncedWithBackendLabel;
    }
    if (record.isFailed) {
      return AppStrings.syncFailedLabel;
    }
    return isOnline ? AppStrings.syncingToBackendLabel : AppStrings.storedLocallyLabel;
  }
}
