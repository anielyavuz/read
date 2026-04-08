import '../../../core/models/notification_preferences.dart';

enum NotificationSettingsStatus { loading, loaded, error }

class NotificationSettingsState {
  final NotificationSettingsStatus status;
  final NotificationPreferences preferences;
  final String? errorMessage;
  final bool hasUnsavedChanges;
  final bool isSaving;

  const NotificationSettingsState({
    this.status = NotificationSettingsStatus.loading,
    this.preferences = const NotificationPreferences(),
    this.errorMessage,
    this.hasUnsavedChanges = false,
    this.isSaving = false,
  });

  NotificationSettingsState copyWith({
    NotificationSettingsStatus? status,
    NotificationPreferences? preferences,
    String? errorMessage,
    bool? hasUnsavedChanges,
    bool? isSaving,
  }) {
    return NotificationSettingsState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      errorMessage: errorMessage ?? this.errorMessage,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
