// Every user-facing string, named instead of inlined - easy to find,
// and ready to localize later.
class AppStrings {
  const AppStrings._();

  static const String appTitle = 'GPS Tracker';

  // Buttons
  static const String startTracking = 'Start tracking';
  static const String stopTracking = 'Stop tracking';
  static const String retry = 'Retry';

  // Summary row labels
  static const String pendingLabel = 'Pending';
  static const String syncedLabel = 'Synced';
  static const String failedLabel = 'Failed';

  // Status banner
  static const String onlineStatus = 'Online';
  static const String syncingStatus = 'Syncing pending records...';
  static const String offlineStatus =
      'Offline — recording locally, will sync when back online';

  // Record list
  static const String emptyRecordsMessage =
      'No location records yet. Tap "Start tracking" to begin.';
  static const String failedSuffixSingular = 'attempt';
  static const String failedSuffixPlural = 'attempts';

  // Per-record sync status, shown on the last-location card and every
  // history row: where the record stands right now (local/synced/etc).
  static const String syncedWithBackendLabel = 'Synced with backend';
  static const String storedLocallyLabel = 'Stored locally';
  static const String syncingToBackendLabel = 'Syncing to backend...';
  static const String syncFailedLabel = 'Sync failed';

  // Last-location card
  static const String lastLocationTitle = 'Last known location';
  static const String noLocationYetMessage =
      'No location captured yet. Tap "Start tracking" to begin.';
}
