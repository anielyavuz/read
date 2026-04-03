import '../../../core/models/notification_preferences.dart';

enum NotificationSettingsStatus { loading, loaded, error }

class NotificationSettingsState {
  final NotificationSettingsStatus status;
  final NotificationPreferences preferences;
  final String? errorMessage;

  const NotificationSettingsState({
    this.status = NotificationSettingsStatus.loading,
    this.preferences = const NotificationPreferences(),
    this.errorMessage,
  });

  NotificationSettingsState copyWith({
    NotificationSettingsStatus? status,
    NotificationPreferences? preferences,
    String? errorMessage,
  }) {
    return NotificationSettingsState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
