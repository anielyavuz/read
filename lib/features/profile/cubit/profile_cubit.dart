import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/services/challenge_service.dart';
import '../../../core/services/challenge_notification_service.dart';
import '../../../core/services/remote_logger_service.dart';
import '../../../core/services/user_profile_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserProfileService _profileService;
  final BadgeService _badgeService;
  final ChallengeService _challengeService;
  final ChallengeNotificationService _challengeNotificationService;

  ProfileCubit({
    required UserProfileService profileService,
    required BadgeService badgeService,
    required ChallengeService challengeService,
    required ChallengeNotificationService challengeNotificationService,
  })  : _profileService = profileService,
        _badgeService = badgeService,
        _challengeService = challengeService,
        _challengeNotificationService = challengeNotificationService,
        super(const ProfileState());

  Future<void> loadProfile() async {
    // Only show loading spinner on the first load
    final isFirstLoad = state.status == ProfileStatus.initial;
    if (isFirstLoad) {
      emit(state.copyWith(status: ProfileStatus.loading));
    }

    try {
      final profile = await _profileService.getProfile();
      if (profile != null) {
        final earnedBadges = await _badgeService.getEarnedBadges();
        emit(state.copyWith(
          status: ProfileStatus.loaded,
          profile: profile,
          earnedBadges: earnedBadges,
        ));
      } else if (state.profile == null) {
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Profile not found',
        ));
      }
    } catch (e) {
      RemoteLoggerService.error('Load profile failed', screen: 'profile', error: e);
      if (state.profile == null) {
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  /// Force-refreshes the profile from Firestore (bypasses cache).
  Future<void> refreshProfile() async {
    _profileService.invalidateCache();
    await loadProfile();
  }

  /// Updates the daily reading goal and refreshes the profile.
  Future<void> updateDailyGoal(int pages) async {
    await _profileService.saveDailyGoal(pages);
    RemoteLoggerService.profile('Daily goal updated',
      details: {'pages': pages});
    _profileService.invalidateCache();
    await loadProfile();
  }

  /// Enables calm mode: leaves all active challenges, cancels their
  /// notifications, then toggles the Firestore flag.
  Future<void> enableCalmMode() async {
    try {
      final myChallenges = await _challengeService.getMyChallenges();
      for (final challenge in myChallenges) {
        await _challengeService.leaveChallenge(challenge.id);
        await _challengeNotificationService
            .cancelForCompletedChallenges([challenge.id]);
      }
      await _profileService.toggleCalmMode(true);
      RemoteLoggerService.profile('Calm mode enabled');
      _profileService.invalidateCache();
      await loadProfile();
    } catch (e) {
      RemoteLoggerService.error('Enable calm mode failed', screen: 'profile', error: e);
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  /// Disables calm mode.
  Future<void> disableCalmMode() async {
    await _profileService.toggleCalmMode(false);
    RemoteLoggerService.profile('Calm mode disabled');
    _profileService.invalidateCache();
    await loadProfile();
  }

  /// Returns the count of active challenges (for confirmation dialog).
  Future<int> getActiveChallengeCount() async {
    try {
      final challenges = await _challengeService.getMyChallenges();
      return challenges.length;
    } catch (_) {
      return 0;
    }
  }
}
