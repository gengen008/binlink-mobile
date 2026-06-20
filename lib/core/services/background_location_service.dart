import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Runs in the task isolate — its only job is holding the foreground service
// notification alive so Android keeps the process running. The actual location
// stream and socket broadcasting happen in the main isolate via
// CollectorProvider._startLocationBroadcast().
@pragma('vm:entry-point')
void _locationTaskEntryPoint() {
  FlutterForegroundTask.setTaskHandler(_LocationKeepAliveHandler());
}

class _LocationKeepAliveHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

class BackgroundLocationService {
  BackgroundLocationService._();

  static const _serviceId = 256;

  /// Call once at app startup (collector flavor only).
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'binlink_collector_location',
        channelName: 'BinLink Collector Service',
        channelDescription: 'Keeps location active during active pickups',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start the foreground service when collector goes online.
  static Future<void> start() async {
    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning) return;
      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        notificationTitle: 'BinLink Collector',
        notificationText: 'Location tracking active',
        callback: _locationTaskEntryPoint,
      );
    } catch (_) {}
  }

  /// Stop the foreground service when collector goes offline.
  static Future<void> stop() async {
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }
}
