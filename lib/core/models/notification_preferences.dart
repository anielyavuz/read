class NotificationPreferences {
  final bool enabled;
  final String weekdayTime;
  final String weekendTime;
  final int readingDurationGoal;
  final bool streakReminder;
  final bool challengeNotifications;

  const NotificationPreferences({
    this.enabled = true,
    this.weekdayTime = '21:00',
    this.weekendTime = '10:00',
    this.readingDurationGoal = 30,
    this.streakReminder = true,
    this.challengeNotifications = true,
  });

  factory NotificationPreferences.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const NotificationPreferences();
    return NotificationPreferences(
      enabled: data['enabled'] as bool? ?? true,
      weekdayTime: data['weekdayTime'] as String? ?? '21:00',
      weekendTime: data['weekendTime'] as String? ?? '10:00',
      readingDurationGoal: data['readingDurationGoal'] as int? ?? 30,
      streakReminder: data['streakReminder'] as bool? ?? true,
      challengeNotifications:
          data['challengeNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      'weekdayTime': weekdayTime,
      'weekendTime': weekendTime,
      'readingDurationGoal': readingDurationGoal,
      'streakReminder': streakReminder,
      'challengeNotifications': challengeNotifications,
    };
  }

  NotificationPreferences copyWith({
    bool? enabled,
    String? weekdayTime,
    String? weekendTime,
    int? readingDurationGoal,
    bool? streakReminder,
    bool? challengeNotifications,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      weekdayTime: weekdayTime ?? this.weekdayTime,
      weekendTime: weekendTime ?? this.weekendTime,
      readingDurationGoal: readingDurationGoal ?? this.readingDurationGoal,
      streakReminder: streakReminder ?? this.streakReminder,
      challengeNotifications:
          challengeNotifications ?? this.challengeNotifications,
    );
  }
}
