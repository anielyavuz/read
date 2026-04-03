import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/challenge.dart';
import '../../../core/services/challenge_service.dart';
import '../../../core/services/challenge_notification_service.dart';
import '../../../core/services/remote_logger_service.dart';
import '../../../core/services/xp_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'challenge_detail_state.dart';

class ChallengeDetailCubit extends Cubit<ChallengeDetailState> {
  final ChallengeService _challengeService;
  final XpService _xpService;
  final ChallengeNotificationService _challengeNotificationService;

  ChallengeDetailCubit({
    required ChallengeService challengeService,
    required XpService xpService,
    required ChallengeNotificationService challengeNotificationService,
  })  : _challengeService = challengeService,
        _xpService = xpService,
        _challengeNotificationService = challengeNotificationService,
        super(const ChallengeDetailState());

  /// Loads a challenge and its participants.
  Future<void> loadChallenge(String id) async {
    emit(state.copyWith(
      status: ChallengeDetailStatus.loading,
      clearError: true,
    ));

    try {
      final challenge = await _challengeService.getChallenge(id);
      final participants =
          await _challengeService.getChallengeParticipants(id);

      // Derive participation + progress from participant list (no extra read)
      final uid = FirebaseAuth.instance.currentUser?.uid;
      bool isParticipating = false;
      int myProgress = 0;
      if (uid != null) {
        for (final p in participants) {
          if (p.userId == uid) {
            isParticipating = true;
            myProgress = p.progress;
            break;
          }
        }
      }

      emit(state.copyWith(
        status: ChallengeDetailStatus.loaded,
        challenge: challenge,
        participants: participants,
        isParticipating: isParticipating,
        myProgress: myProgress,
      ));
    } catch (e) {
      RemoteLoggerService.error('Load challenge failed', screen: 'challenge', error: e);
      emit(state.copyWith(
        status: ChallengeDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Joins the current challenge and schedules smart notifications.
  /// [l10n] is needed to build localized notification text at schedule time.
  Future<void> joinChallenge(AppLocalizations l10n) async {
    final challenge = state.challenge;
    if (challenge == null) return;

    emit(state.copyWith(status: ChallengeDetailStatus.joining));

    try {
      await _challengeService.joinChallenge(challenge.id);
      RemoteLoggerService.challenge('Challenge joined',
        challengeId: challenge.id,
        challengeTitle: challenge.title,
        challengeType: challenge.type.name);

      // Award +50 XP for joining
      await _xpService.awardChallengeJoinXp();

      // Schedule smart notifications for this challenge
      await _scheduleChallengeNotifications(challenge, l10n);

      // Reload challenge data
      final updatedChallenge =
          await _challengeService.getChallenge(challenge.id);
      final participants =
          await _challengeService.getChallengeParticipants(challenge.id);

      emit(state.copyWith(
        status: ChallengeDetailStatus.loaded,
        challenge: updatedChallenge,
        participants: participants,
        isParticipating: true,
        myProgress: 0,
      ));
    } catch (e) {
      RemoteLoggerService.error('Join challenge failed', screen: 'challenge', error: e);
      emit(state.copyWith(
        status: ChallengeDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Leaves the current challenge and cancels its notifications.
  Future<void> leaveChallenge() async {
    final challenge = state.challenge;
    if (challenge == null) return;

    emit(state.copyWith(status: ChallengeDetailStatus.leaving));

    try {
      await _challengeService.leaveChallenge(challenge.id);
      RemoteLoggerService.challenge('Challenge left',
        challengeId: challenge.id,
        challengeTitle: challenge.title,
        challengeType: challenge.type.name);

      // Cancel scheduled notifications for this challenge
      await _challengeNotificationService.cancelForChallenge(challenge.id);

      // Reload challenge data
      final updatedChallenge =
          await _challengeService.getChallenge(challenge.id);
      final participants =
          await _challengeService.getChallengeParticipants(challenge.id);

      emit(state.copyWith(
        status: ChallengeDetailStatus.loaded,
        challenge: updatedChallenge,
        participants: participants,
        isParticipating: false,
        myProgress: 0,
      ));
    } catch (e) {
      RemoteLoggerService.error('Leave challenge failed', screen: 'challenge', error: e);
      emit(state.copyWith(
        status: ChallengeDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Builds type-specific localized notification strings and schedules them.
  Future<void> _scheduleChallengeNotifications(
    Challenge challenge,
    AppLocalizations l10n,
  ) async {
    try {
      final title = challenge.title;

      // Build type-specific last day body
      final String lastDayBody;
      switch (challenge.type) {
        case ChallengeType.pages:
        case ChallengeType.readAlong:
          lastDayBody = l10n.challengeLastDayPageBody(
            title,
            challenge.targetPages ?? 0,
          );
          break;
        case ChallengeType.sprint:
          lastDayBody = l10n.challengeLastDaySprintBody(title);
          break;
        case ChallengeType.genre:
          lastDayBody = l10n.challengeLastDayGenreBody(title);
          break;
      }

      // Build type-specific mid-point body
      final String midPointBody;
      switch (challenge.type) {
        case ChallengeType.pages:
        case ChallengeType.readAlong:
          midPointBody = l10n.challengeMidPointPageBody(
            title,
            challenge.targetPages ?? 0,
          );
          break;
        case ChallengeType.sprint:
          midPointBody = l10n.challengeMidPointSprintBody(
            title,
            challenge.targetMinutes ?? 0,
          );
          break;
        case ChallengeType.genre:
          midPointBody = l10n.challengeMidPointGenreBody(
            title,
            challenge.targetBooks ?? 0,
          );
          break;
      }

      await _challengeNotificationService.scheduleForChallenge(
        challenge: challenge,
        lastDayTitle: l10n.challengeLastDayTitle,
        lastDayBody: lastDayBody,
        midPointTitle: l10n.challengeMidPointTitle,
        midPointBody: midPointBody,
      );
    } catch (_) {
      // Notification scheduling failure is non-critical
    }
  }
}
