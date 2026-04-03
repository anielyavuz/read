import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules a local notification at 22:00 if the user hasn't completed
/// their daily reading goal. Cancelled when the goal is met via Focus Mode.
/// Re-scheduled automatically on next app open (HomeCubit.loadHome).
class DailyGoalNotificationService {
  static const _channelId = 'daily_goal_reminder';
  static const _channelName = 'Daily Goal Reminders';
  static const _notificationId = 99001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

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
  }

  /// Schedules a 22:00 notification if the daily goal is not yet met.
  /// If the goal is already met or it's past 22:00, does nothing.
  Future<void> scheduleIfNeeded({
    required int dailyGoal,
    required int pagesReadToday,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    // Goal already met — cancel any existing notification
    if (pagesReadToday >= dailyGoal) {
      await cancel();
      return;
    }

    // Only schedule if before 22:00
    final now = DateTime.now();
    final today22 = DateTime(now.year, now.month, now.day, 22, 0);
    if (now.isAfter(today22)) return;

    final tzDate = tz.TZDateTime.from(today22, tz.local);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily reading goal reminders',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _notificationId,
      title,
      body,
      tzDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels the daily goal reminder (called when goal is met).
  Future<void> cancel() async {
    if (!_initialized) await init();
    await _plugin.cancel(_notificationId);
  }
}
