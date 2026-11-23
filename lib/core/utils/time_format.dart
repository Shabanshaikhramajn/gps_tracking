// Small shared time-formatting helpers, kept in one place instead of
// repeated inline in every widget that shows a captured timestamp.
class TimeFormat {
  const TimeFormat._();

  // Local hh:mm:ss, e.g. "14:03:27".
  static String clock(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    return '${_twoDigits(local.hour)}:'
        '${_twoDigits(local.minute)}:'
        '${_twoDigits(local.second)}';
  }

  // A short "how long ago" label, e.g. "just now", "12s ago", "3m ago".
  // Not a live-ticking clock - fine for a UI that rebuilds periodically.
  static String relative(DateTime dateTime, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final Duration elapsed = reference.difference(dateTime);
    if (elapsed.inSeconds < 5) {
      return 'just now';
    }
    if (elapsed.inMinutes < 1) {
      return '${elapsed.inSeconds}s ago';
    }
    if (elapsed.inHours < 1) {
      return '${elapsed.inMinutes}m ago';
    }
    return '${elapsed.inHours}h ago';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
