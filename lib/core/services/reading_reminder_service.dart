import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_preferences.dart';

/// Schedules daily local reading reminder notifications based on user preferences.
///
/// Uses [flutter_local_notifications] zonedSchedule with [DateTimeComponents.dayOfWeekAndTime]
/// to repeat every week on matching days (weekday vs weekend).
///
/// Notification fires 10 minutes BEFORE the user's configured reading time.
/// If the resulting time falls in quiet hours (23:00–07:00), it is skipped.
class ReadingReminderService {
  static const _channelId = 'reading_reminders';
  static const _channelName = 'Reading Reminders';

  // Fixed notification IDs (weekday Mon-Fri = 1001-1005, weekend Sat-Sun = 1006-1007)
  static const _baseWeekdayId = 1001;
  static const _baseWeekendId = 1006;

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

  /// Request notification permissions on Android 13+ and iOS.
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Schedules reading reminder notifications based on user preferences.
  /// Cancels all existing reminders first, then schedules new ones.
  ///
  /// [title] and [body] should be localized strings.
  Future<void> scheduleReminders({
    required NotificationPreferences prefs,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    // Always cancel existing reminders first
    await cancelAll();

    // If notifications are disabled, just cancel and return
    if (!prefs.enabled) {
      dev.log('Notifications disabled — skipped scheduling',
          name: 'ReadingReminderService');
      return;
    }

    // Schedule weekday reminders (Monday–Friday, days 1-5)
    final weekdayTime = _parseTime(prefs.weekdayTime);
    if (weekdayTime != null) {
      final reminderTime = _subtractMinutes(weekdayTime, 10);
      if (!_isQuietHour(reminderTime)) {
        for (int day = DateTime.monday; day <= DateTime.friday; day++) {
          await _scheduleWeekly(
            id: _baseWeekdayId + (day - DateTime.monday),
            title: title,
            body: body,
            hour: reminderTime.$1,
            minute: reminderTime.$2,
            dayOfWeek: day,
          );
        }
        dev.log(
          'Scheduled weekday reminders at ${reminderTime.$1}:${reminderTime.$2.toString().padLeft(2, '0')}',
          name: 'ReadingReminderService',
        );
      }
    }

    // Schedule weekend reminders (Saturday–Sunday, days 6-7)
    final weekendTime = _parseTime(prefs.weekendTime);
    if (weekendTime != null) {
      final reminderTime = _subtractMinutes(weekendTime, 10);
      if (!_isQuietHour(reminderTime)) {
        for (int day = DateTime.saturday; day <= DateTime.sunday; day++) {
          await _scheduleWeekly(
            id: _baseWeekendId + (day - DateTime.saturday),
            title: title,
            body: body,
            hour: reminderTime.$1,
            minute: reminderTime.$2,
            dayOfWeek: day,
          );
        }
        dev.log(
          'Scheduled weekend reminders at ${reminderTime.$1}:${reminderTime.$2.toString().padLeft(2, '0')}',
          name: 'ReadingReminderService',
        );
      }
    }
  }

  /// Cancels all scheduled reading reminders.
  Future<void> cancelAll() async {
    if (!_initialized) await init();
    // Cancel weekday IDs (Mon-Fri)
    for (int i = 0; i < 5; i++) {
      await _plugin.cancel(_baseWeekdayId + i);
    }
    // Cancel weekend IDs (Sat-Sun)
    for (int i = 0; i < 2; i++) {
      await _plugin.cancel(_baseWeekendId + i);
    }
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int dayOfWeek,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = _nextInstanceOfWeekdayTime(now, dayOfWeek, hour, minute);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily reading time reminders',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Returns the next TZDateTime for a given [dayOfWeek] (1=Mon, 7=Sun) at [hour]:[minute].
  tz.TZDateTime _nextInstanceOfWeekdayTime(
    tz.TZDateTime now,
    int dayOfWeek,
    int hour,
    int minute,
  ) {
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Advance to the correct day of week
    while (scheduled.weekday != dayOfWeek) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // If the time is in the past, move to next week
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }

  /// Parses "HH:MM" to (hour, minute) tuple. Returns null on invalid input.
  (int, int)? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }

  /// Subtracts [minutes] from a (hour, minute) tuple, wrapping around midnight.
  (int, int) _subtractMinutes((int, int) time, int minutes) {
    var totalMinutes = time.$1 * 60 + time.$2 - minutes;
    if (totalMinutes < 0) totalMinutes += 24 * 60;
    return (totalMinutes ~/ 60, totalMinutes % 60);
  }

  /// Returns true if the time falls in quiet hours (23:00–07:00).
  bool _isQuietHour((int, int) time) {
    final hour = time.$1;
    return hour >= 23 || hour < 7;
  }
}
