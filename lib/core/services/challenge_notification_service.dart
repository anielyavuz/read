import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/challenge.dart';

/// Schedules smart local notifications when a user joins a challenge.
/// Cancels them when the user leaves or completes the challenge.
///
/// Notification strategy per challenge type:
/// - All: "Last day" reminder on endDate minus 1 day at 10:00
/// - Pages / ReadAlong / Sprint (>7 days): Mid-point reminder at 10:00
/// - Short challenges (<=3 days): Only a last-day reminder
///
/// Notifications are cancelled automatically when:
/// - User leaves the challenge
/// - User completes the challenge target
class ChallengeNotificationService {
  static const _channelId = 'challenge_reminders';
  static const _channelName = 'Challenge Reminders';

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

  /// Schedules smart notifications for a challenge the user just joined.
  /// [title] and [bodyLastDay] / [bodyMidPoint] are already localized strings.
  Future<void> scheduleForChallenge({
    required Challenge challenge,
    required String lastDayTitle,
    required String lastDayBody,
    required String midPointTitle,
    required String midPointBody,
  }) async {
    if (!_initialized) await init();

    final now = DateTime.now();
    final endDate = challenge.endDate;
    final totalDays = endDate.difference(challenge.startDate).inDays;

    // --- Last day notification (1 day before endDate at 10:00) ---
    final lastDayDate = endDate.subtract(const Duration(days: 1));
    final lastDayAt10 = DateTime(
      lastDayDate.year,
      lastDayDate.month,
      lastDayDate.day,
      10,
      0,
    );
    if (lastDayAt10.isAfter(now)) {
      await _scheduleNotification(
        id: _notificationId(challenge.id, 0),
        title: lastDayTitle,
        body: lastDayBody,
        scheduledDate: lastDayAt10,
      );
    }

    // --- Mid-point notification (only for challenges > 7 days) ---
    if (totalDays > 7) {
      final midDate = challenge.startDate.add(Duration(days: totalDays ~/ 2));
      final midPointDate = DateTime(
        midDate.year,
        midDate.month,
        midDate.day,
        10,
        0,
      );
      if (midPointDate.isAfter(now)) {
        await _scheduleNotification(
          id: _notificationId(challenge.id, 1),
          title: midPointTitle,
          body: midPointBody,
          scheduledDate: midPointDate,
        );
      }
    }
  }

  /// Cancels all scheduled notifications for a challenge.
  /// Call when user leaves or completes a challenge.
  Future<void> cancelForChallenge(String challengeId) async {
    if (!_initialized) await init();
    // Cancel both possible notification slots (last day + mid-point)
    await _plugin.cancel(_notificationId(challengeId, 0));
    await _plugin.cancel(_notificationId(challengeId, 1));
  }

  /// Cancels notifications for multiple completed challenges at once.
  Future<void> cancelForCompletedChallenges(
      List<String> completedChallengeIds) async {
    for (final id in completedChallengeIds) {
      await cancelForChallenge(id);
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Reminders for active challenges',
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
      id,
      title,
      body,
      tzDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Generates a deterministic notification ID from challenge ID + slot index.
  /// Uses a stable hash based on character codes (survives app restarts).
  int _notificationId(String challengeId, int slot) {
    int hash = 0x811c9dc5; // FNV-1a offset basis
    for (int i = 0; i < challengeId.length; i++) {
      hash ^= challengeId.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF; // FNV prime, keep 31-bit
    }
    return (hash & 0x7FFFFFFF) + slot;
  }
}
