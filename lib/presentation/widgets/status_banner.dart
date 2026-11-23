import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// The colored bar showing online/offline/mid-sync. Takes plain booleans
// rather than the bloc's state, so it stays reusable and easy to test.
class StatusBanner extends StatelessWidget {
  const StatusBanner({required this.isOnline, required this.isSyncing, super.key});

  final bool isOnline;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    if (!isOnline) {
      label = AppStrings.offlineStatus;
      color = AppColors.offline;
    } else if (isSyncing) {
      label = AppStrings.syncingStatus;
      color = AppColors.syncing;
    } else {
      label = AppStrings.onlineStatus;
      color = AppColors.online;
    }

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(isOnline ? Icons.wifi : Icons.wifi_off, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          if (isSyncing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
