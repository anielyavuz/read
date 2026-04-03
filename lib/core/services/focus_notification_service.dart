import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    as foreground;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FocusNotificationService {
  static const _channelId = 'focus_timer';
  static const _channelName = 'Focus Timer';
  static const _notificationId = 42;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _foregroundRunning = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;

    // Initialize foreground task for Android
    if (Platform.isAndroid) {
      foreground.FlutterForegroundTask.init(
        androidNotificationOptions:
            foreground.AndroidNotificationOptions(
          channelId: _channelId,
          channelName: _channelName,
          channelDescription: 'Shows the active focus timer',
          channelImportance:
              foreground.NotificationChannelImportance.LOW,
          priority: foreground.NotificationPriority.LOW,
          visibility:
              foreground.NotificationVisibility.VISIBILITY_PUBLIC,
        ),
        iosNotificationOptions: const foreground.IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: foreground.ForegroundTaskOptions(
          eventAction: foreground.ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: false);
    } else if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      final notifPermission =
          await foreground.FlutterForegroundTask
              .checkNotificationPermission();
      if (notifPermission !=
          foreground.NotificationPermission.granted) {
        await foreground.FlutterForegroundTask
            .requestNotificationPermission();
      }
    }
  }

  /// Start the foreground service with initial timer state.
  Future<void> startForegroundTimer({String? bookTitle}) async {
    if (!_initialized) await init();

    final title =
        bookTitle != null ? 'Reading: $bookTitle' : 'Focus Mode';

    if (Platform.isAndroid) {
      _foregroundRunning = true;
      await foreground.FlutterForegroundTask.startService(
        notificationTitle: title,
        notificationText: '00:00 elapsed',
      );
    } else {
      await showTimerNotification(title: title, body: '00:00 elapsed');
    }
  }

  /// Update the foreground notification with current elapsed time.
  Future<void> updateTimerNotification({
    required Duration elapsed,
    String? bookTitle,
  }) async {
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds.remainder(60);
    final timeStr = '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    final title =
        bookTitle != null ? 'Reading: $bookTitle' : 'Focus Mode';
    final body = '$timeStr elapsed';

    if (Platform.isAndroid && _foregroundRunning) {
      foreground.FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: body,
      );
    } else {
      await showTimerNotification(title: title, body: body);
    }
  }

  /// Stop the foreground service and cancel notification.
  Future<void> cancelTimerNotification() async {
    if (Platform.isAndroid && _foregroundRunning) {
      _foregroundRunning = false;
      await foreground.FlutterForegroundTask.stopService();
    } else {
      await _plugin.cancel(_notificationId);
    }
  }

  Future<void> showTimerNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Shows the active focus timer on lock screen',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      usesChronometer: true,
      chronometerCountDown: false,
      category: AndroidNotificationCategory.progress,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(_notificationId, title, body, details);
  }
}
