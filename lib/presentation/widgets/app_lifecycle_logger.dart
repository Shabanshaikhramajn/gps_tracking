import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';

// Logs every app-lifecycle transition (resumed/paused/etc) for
// observability; background tracking itself is handled natively - see README.
class AppLifecycleLogger extends StatefulWidget {
  const AppLifecycleLogger({required this.child, super.key});

  final Widget child;

  @override
  State<AppLifecycleLogger> createState() => _AppLifecycleLoggerState();
}

class _AppLifecycleLoggerState extends State<AppLifecycleLogger>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A plain switch statement, so every non-empty case needs its own
    // explicit break (no fallthrough in Dart).
    switch (state) {
      case AppLifecycleState.resumed:
        AppLogger.info('App resumed to foreground.', name: 'AppLifecycle');
        break;
      case AppLifecycleState.inactive:
        AppLogger.info('App became inactive (e.g. a system dialog or app switcher appeared).', name: 'AppLifecycle');
        break;
      case AppLifecycleState.paused:
        AppLogger.info(
          'App moved to background / screen locked. Tracking keeps running '
          'via the platform background mechanisms described in README.md.',
          name: 'AppLifecycle',
        );
        break;
      case AppLifecycleState.detached:
        AppLogger.warning(
          'App engine detached from the platform view - the Dart isolate '
          'may be torn down shortly. If the user force-quit the app, '
          'tracking stops here; this is expected OS behavior, not a bug.',
          name: 'AppLifecycle',
        );
        break;
      case AppLifecycleState.hidden:
        AppLogger.info('App window hidden.', name: 'AppLifecycle');
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
