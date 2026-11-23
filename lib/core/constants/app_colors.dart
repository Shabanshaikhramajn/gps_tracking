import 'package:flutter/material.dart';

// Every color this app uses, named by meaning, not appearance.
// Some share a value (pending/offline are both orange) on purpose.
class AppColors {
  const AppColors._();

  // Theme
  static const Color seed = Colors.indigo;

  // Record status
  static const Color pending = Colors.orange;
  static const Color synced = Colors.green;
  static const Color failed = Colors.red;

  // Connectivity / sync banner
  static const Color online = Colors.green;
  static const Color offline = Colors.orange;
  static const Color syncing = Colors.blue;

  // Misc
  static const Color stopTrackingButton = Colors.redAccent;
  static const Color emptyStateIcon = Colors.grey;
}
