import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/time_format.dart';
import '../../domain/entities/location_record.dart';

// One history-list row: coordinates, time, status dot/label, and a
// Retry action. [isOnline] only changes the wording for pending records.
class RecordTile extends StatelessWidget {
  const RecordTile({
    required this.record,
    required this.isOnline,
    this.onRetry,
    super.key,
  });

  final LocationRecord record;
  final bool isOnline;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final String timeLabel = TimeFormat.clock(record.capturedAt);
    return ListTile(
      leading: _StatusDot(record: record),
      title: Text(
        '${record.latitude.toStringAsFixed(5)}, ${record.longitude.toStringAsFixed(5)}',
      ),
      subtitle: Text('Captured at $timeLabel · ${_statusLabel()}'),
      trailing: onRetry != null
          ? TextButton(onPressed: onRetry, child: const Text(AppStrings.retry))
          : null,
    );
  }

  String _statusLabel() {
    switch (record.status) {
      case LocationRecordStatus.synced:
        return AppStrings.syncedWithBackendLabel;
      case LocationRecordStatus.pending:
        return isOnline
            ? AppStrings.syncingToBackendLabel
            : AppStrings.storedLocallyLabel;
      case LocationRecordStatus.failed:
        final String attemptWord = record.attempts == 1
            ? AppStrings.failedSuffixSingular
            : AppStrings.failedSuffixPlural;
        return '${AppStrings.syncFailedLabel} (${record.attempts} $attemptWord)';
    }
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.record});

  final LocationRecord record;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (record.status) {
      LocationRecordStatus.pending => AppColors.pending,
      LocationRecordStatus.synced => AppColors.synced,
      LocationRecordStatus.failed => AppColors.failed,
    };
    return Icon(Icons.circle, color: color, size: 14);
  }
}
