import '../../../core/models/inbox_notification.dart';

enum InboxStatus { initial, loading, loaded, error }

class InboxState {
  final InboxStatus status;
  final List<InboxNotification> notifications;
  final String? errorMessage;

  const InboxState({
    this.status = InboxStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  InboxState copyWith({
    InboxStatus? status,
    List<InboxNotification>? notifications,
    String? errorMessage,
  }) {
    return InboxState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
