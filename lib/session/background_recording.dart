import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps recording alive on Android when the screen turns off or the user
/// switches apps. Android 14+ only allows background mic access from a
/// foreground service of type `microphone`, started while the app is visible.
class BackgroundRecording {
  BackgroundRecording._();

  static const _stopButton = 'stop';

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static void Function()? _onStop;

  static void initCommunicationPort() {
    if (supported) FlutterForegroundTask.initCommunicationPort();
  }

  /// Returns false if the service couldn't start; recording still works
  /// while the app stays on screen.
  static Future<bool> start({required void Function() onStopPressed}) async {
    if (!supported) return false;
    try {
      final permission = await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'live_session',
          channelName: 'Live translation',
          channelDescription: 'Shown while Lt is listening and translating.',
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          allowWakeLock: true,
          allowWifiLock: true,
          allowAutoRestart: false,
          stopWithTask: true,
        ),
      );
      _onStop = onStopPressed;
      FlutterForegroundTask.addTaskDataCallback(_onData);
      final result = await FlutterForegroundTask.startService(
        serviceId: 1001,
        serviceTypes: [ForegroundServiceTypes.microphone],
        notificationTitle: 'Lt is listening',
        notificationText: 'Tap to return to the live translation',
        notificationButtons: const [NotificationButton(id: _stopButton, text: 'Stop')],
        notificationInitialRoute: '/',
        callback: _startCallback,
      );
      return result is ServiceRequestSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    if (!supported) return;
    FlutterForegroundTask.removeTaskDataCallback(_onData);
    _onStop = null;
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }

  static void _onData(Object data) {
    if (data == _stopButton) _onStop?.call();
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_LiveTaskHandler());
}

/// The recording itself runs in the main isolate; this handler only relays
/// the notification's Stop button.
class _LiveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain(id);
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
