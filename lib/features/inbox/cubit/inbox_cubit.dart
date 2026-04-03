import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/inbox_service.dart';
import '../../../core/services/challenge_service.dart';
import 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  final InboxService _inboxService;
  final ChallengeService _challengeService;

  InboxCubit({
    required InboxService inboxService,
    required ChallengeService challengeService,
  })  : _inboxService = inboxService,
        _challengeService = challengeService,
        super(const InboxState());

  Future<void> loadNotifications() async {
    emit(state.copyWith(status: InboxStatus.loading));
    try {
      final notifications = await _inboxService.getNotifications();
      emit(state.copyWith(
        status: InboxStatus.loaded,
        notifications: notifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InboxStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> acceptInvite(String notificationId, String challengeId) async {
    try {
      // Join first — only mark as accepted if join succeeds
      await _challengeService.joinChallenge(challengeId);
      await _inboxService.acceptInvite(notificationId);
      await loadNotifications();
    } catch (e) {
      emit(state.copyWith(
        status: InboxStatus.error,
        errorMessage: e.toString(),
      ));
      // Reload to reflect actual state
      await loadNotifications();
    }
  }

  Future<void> rejectInvite(String notificationId) async {
    try {
      await _inboxService.rejectInvite(notificationId);
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _inboxService.markAsRead(notificationId);
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> deleteNotification(String notificationId) async {
    // Optimistic removal from list
    final updated =
        state.notifications.where((n) => n.id != notificationId).toList();
    emit(state.copyWith(notifications: updated));

    try {
      await _inboxService.deleteNotification(notificationId);
    } catch (_) {
      // Revert on failure
      await loadNotifications();
    }
  }
}
