import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// A plain centered message with an optional icon, for any screen with
// nothing to show yet (here: the record list before the first fix).
class EmptyState extends StatelessWidget {
  const EmptyState({required this.message, this.icon, super.key});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 40, color: AppColors.emptyStateIcon),
              const SizedBox(height: 12),
            ],
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
