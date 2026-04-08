import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/notification_preferences.dart';
import '../../../core/services/challenge_notification_service.dart';
import '../../../core/services/challenge_service.dart';
import '../../../core/services/notification_preferences_service.dart';
import '../../../core/services/reading_reminder_service.dart';
import 'notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final NotificationPreferencesService _service;
  final ReadingReminderService _reminderService;
  final ChallengeNotificationService _challengeNotifService;
  final ChallengeService _challengeService;

  /// Localized notification title & body, set from the screen via [setLocalizedStrings].
  String _reminderTitle = 'Time to read!';
  String _reminderBody = 'Your reading session starts soon. You got this!';

  /// Saved snapshot to detect unsaved changes.
  NotificationPreferences? _savedPrefs;

  NotificationSettingsCubit({
    required NotificationPreferencesService service,
    required ReadingReminderService reminderService,
    required ChallengeNotificationService challengeNotifService,
    required ChallengeService challengeService,
  })  : _service = service,
        _reminderService = reminderService,
        _challengeNotifService = challengeNotifService,
        _challengeService = challengeService,
        super(const NotificationSettingsState());

  /// Call from the screen to provide localized notification content.
  void setLocalizedStrings({
    required String title,
    required String body,
  }) {
    _reminderTitle = title;
    _reminderBody = body;
  }

  Future<void> loadPreferences() async {
    emit(state.copyWith(status: NotificationSettingsStatus.loading));
    try {
      final prefs = await _service.getPreferences();
      _savedPrefs = prefs;
      emit(state.copyWith(
        status: NotificationSettingsStatus.loaded,
        preferences: prefs,
        hasUnsavedChanges: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationSettingsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void toggleEnabled() {
    final updated = state.preferences.copyWith(
      enabled: !state.preferences.enabled,
    );
    emit(state.copyWith(
      preferences: updated,
      hasUnsavedChanges: _hasChanges(updated),
    ));
  }

  void updateWeekdayTime(String time) {
    final updated = state.preferences.copyWith(weekdayTime: time);
    emit(state.copyWith(
      preferences: updated,
      hasUnsavedChanges: _hasChanges(updated),
    ));
  }

  void updateWeekendTime(String time) {
    final updated = state.preferences.copyWith(weekendTime: time);
    emit(state.copyWith(
      preferences: updated,
      hasUnsavedChanges: _hasChanges(updated),
    ));
  }

  void setReadingDuration(int minutes) {
    final updated = state.preferences.copyWith(readingDurationGoal: minutes);
    emit(state.copyWith(
      preferences: updated,
      hasUnsavedChanges: _hasChanges(updated),
    ));
  }

  void toggleStreakReminder() {
    final updated = state.preferences.copyWith(
      streakReminder: !state.preferences.streakReminder,
    );
    emit(state.copyWith(
      preferences: updated,
      hasUnsavedChanges: _hasChanges(updated),
    ));
  }

  void toggleChallengeNotifications() {
    final updated = state.preferences.copyWith(
      challengeNotifications: !state.preferences.challengeNotifications,
    );
    emit(state.copyWith(
      preferences: updated,
      hasUnsavedChanges: _hasChanges(updated),
    ));
  }

  /// Persists all pending changes to Firestore and reschedules notifications.
  Future<void> saveChanges() async {
    if (!state.hasUnsavedChanges) return;

    emit(state.copyWith(isSaving: true));
    try {
      final prefs = state.preferences;
      await _service.updatePreferences(prefs);
      await _rescheduleReminders(prefs);
      await _handleChallengeNotificationChange(prefs);
      _savedPrefs = prefs;
      emit(state.copyWith(
        hasUnsavedChanges: false,
        isSaving: false,
      ));
    } catch (e) {
      emit(state.copyWith(isSaving: false));
      dev.log('Failed to save notification settings: $e',
          name: 'NotificationSettingsCubit');
      rethrow;
    }
  }

  bool _hasChanges(NotificationPreferences current) {
    final saved = _savedPrefs;
    if (saved == null) return false;
    return current.enabled != saved.enabled ||
        current.weekdayTime != saved.weekdayTime ||
        current.weekendTime != saved.weekendTime ||
        current.readingDurationGoal != saved.readingDurationGoal ||
        current.streakReminder != saved.streakReminder ||
        current.challengeNotifications != saved.challengeNotifications;
  }

  /// Reschedules local reading reminders whenever time or enabled state changes.
  Future<void> _rescheduleReminders(NotificationPreferences prefs) async {
    try {
      await _reminderService.scheduleReminders(
        prefs: prefs,
        title: _reminderTitle,
        body: _reminderBody,
      );
      dev.log('Reading reminders rescheduled',
          name: 'NotificationSettingsCubit');
    } catch (e) {
      dev.log('Failed to reschedule reminders: $e',
          name: 'NotificationSettingsCubit');
    }
  }

  /// If challenge notifications were just turned off, cancel all active
  /// challenge notifications immediately.
  Future<void> _handleChallengeNotificationChange(
    NotificationPreferences prefs,
  ) async {
    final wasChallengeEnabled = _savedPrefs?.challengeNotifications ?? true;
    final isChallengeEnabled = prefs.challengeNotifications && prefs.enabled;

    if (wasChallengeEnabled && !isChallengeEnabled) {
      try {
        final challenges = await _challengeService.getMyChallenges();
        final ids = challenges.map((c) => c.id).toList();
        await _challengeNotifService.cancelForCompletedChallenges(ids);
        dev.log('Cancelled ${ids.length} challenge notifications',
            name: 'NotificationSettingsCubit');
      } catch (e) {
        dev.log('Failed to cancel challenge notifications: $e',
            name: 'NotificationSettingsCubit');
      }
    }
  }
}
