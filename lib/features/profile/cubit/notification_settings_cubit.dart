import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/notification_preferences.dart';
import '../../../core/services/notification_preferences_service.dart';
import '../../../core/services/reading_reminder_service.dart';
import 'notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final NotificationPreferencesService _service;
  final ReadingReminderService _reminderService;

  /// Localized notification title & body, set from the screen via [setLocalizedStrings].
  String _reminderTitle = 'Time to read!';
  String _reminderBody = 'Your reading session starts soon. You got this!';

  NotificationSettingsCubit({
    required NotificationPreferencesService service,
    required ReadingReminderService reminderService,
  })  : _service = service,
        _reminderService = reminderService,
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
      emit(state.copyWith(
        status: NotificationSettingsStatus.loaded,
        preferences: prefs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationSettingsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> toggleEnabled() async {
    final updated = state.preferences.copyWith(
      enabled: !state.preferences.enabled,
    );
    emit(state.copyWith(preferences: updated));
    await _service.updatePreferences(updated);
    await _rescheduleReminders(updated);
  }

  Future<void> updateWeekdayTime(String time) async {
    final updated = state.preferences.copyWith(weekdayTime: time);
    emit(state.copyWith(preferences: updated));
    await _service.updatePreferences(updated);
    await _rescheduleReminders(updated);
  }

  Future<void> updateWeekendTime(String time) async {
    final updated = state.preferences.copyWith(weekendTime: time);
    emit(state.copyWith(preferences: updated));
    await _service.updatePreferences(updated);
    await _rescheduleReminders(updated);
  }

  Future<void> setReadingDuration(int minutes) async {
    final updated = state.preferences.copyWith(readingDurationGoal: minutes);
    emit(state.copyWith(preferences: updated));
    await _service.updatePreferences(updated);
  }

  Future<void> toggleStreakReminder() async {
    final updated = state.preferences.copyWith(
      streakReminder: !state.preferences.streakReminder,
    );
    emit(state.copyWith(preferences: updated));
    await _service.updatePreferences(updated);
  }

  Future<void> toggleWeeklyReport() async {
    final updated = state.preferences.copyWith(
      weeklyReport: !state.preferences.weeklyReport,
    );
    emit(state.copyWith(preferences: updated));
    await _service.updatePreferences(updated);
  }

  /// Reschedules local reading reminders whenever time or enabled state changes.
  Future<void> _rescheduleReminders(NotificationPreferences prefs) async {
    try {
      await _reminderService.scheduleReminders(
        prefs: prefs,
        title: _reminderTitle,
        body: _reminderBody,
      );
      dev.log('Reading reminders rescheduled', name: 'NotificationSettingsCubit');
    } catch (e) {
      dev.log('Failed to reschedule reminders: $e',
          name: 'NotificationSettingsCubit');
    }
  }
}
