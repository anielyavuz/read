import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/challenge.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/challenge_notification_service.dart';
import '../../../core/services/challenge_service.dart';
import '../../../core/services/daily_goal_notification_service.dart';
import '../../../core/services/notification_preferences_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/reader_profile_repository.dart';
import '../../../core/services/reading_reminder_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/services/friendship_service.dart';
import '../../../core/services/inbox_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final UserProfileService _profileService;
  final FriendshipService _friendshipService;
  final InboxService _inboxService;
  final ActivityService _activityService;
  final ReaderProfileRepository _readerProfileRepo;
  final ChallengeService _challengeService;
  final NotificationService _notificationService;
  final DailyGoalNotificationService _dailyGoalNotificationService;
  final ReadingReminderService _readingReminderService;
  final NotificationPreferencesService _notificationPreferencesService;
  final ChallengeNotificationService _challengeNotificationService;

  HomeCubit({
    required UserProfileService profileService,
    required FriendshipService friendshipService,
    required InboxService inboxService,
    required ActivityService activityService,
    required ReaderProfileRepository readerProfileRepository,
    required ChallengeService challengeService,
    required NotificationService notificationService,
    required DailyGoalNotificationService dailyGoalNotificationService,
    required ReadingReminderService readingReminderService,
    required NotificationPreferencesService notificationPreferencesService,
    required ChallengeNotificationService challengeNotificationService,
  })  : _profileService = profileService,
        _friendshipService = friendshipService,
        _inboxService = inboxService,
        _activityService = activityService,
        _readerProfileRepo = readerProfileRepository,
        _challengeService = challengeService,
        _notificationService = notificationService,
        _dailyGoalNotificationService = dailyGoalNotificationService,
        _readingReminderService = readingReminderService,
        _notificationPreferencesService = notificationPreferencesService,
        _challengeNotificationService = challengeNotificationService,
        super(const HomeState());

  Future<void> loadHome() async {
    // Only show loading spinner on the very first load.
    // Subsequent loads keep existing data visible (soft refresh).
    final isFirstLoad = state.status == HomeStatus.initial;
    if (isFirstLoad) {
      emit(state.copyWith(status: HomeStatus.loading));
    }

    try {
      // Refresh FCM token on every home load
      _notificationService.refreshFcmToken();

      // Fetch profile (served from cache if fresh, otherwise Firestore)
      final profile = await _profileService.getProfile();
      if (profile == null) {
        emit(state.copyWith(
          status: HomeStatus.error,
          errorMessage: 'Profile not found',
        ));
        return;
      }

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final pagesReadToday =
          profile.pagesReadTodayDate == todayStr ? profile.pagesReadToday : 0;

      // Fetch secondary data — skip social/challenge in calm mode
      int pendingFriends = 0;
      int unreadInbox = 0;
      List<Challenge> myChallenges = [];

      if (!profile.calmMode) {
        final results = await Future.wait([
          _safeFetch(() => _friendshipService.getPendingRequestCount()),
          _safeFetch(() => _inboxService.getUnreadCount()),
        ]);
        pendingFriends = results[0];
        unreadInbox = results[1];
        myChallenges = await _safeFetchList(() => _challengeService.getMyChallenges());
      }

      final activityEntries = await _activityService.getRecentEntries(limit: 20);
      final readerProfile = await _readerProfileRepo.getReaderProfile();

      emit(state.copyWith(
        status: HomeStatus.loaded,
        userProfile: profile,
        pagesReadToday: pagesReadToday,
        pendingFriendRequests: pendingFriends,
        unreadInboxCount: unreadInbox,
        activityEntries: activityEntries,
        readerProfile: readerProfile,
        myChallenges: myChallenges,
      ));

      // Daily goal notification is scheduled from the UI layer (home_tab)
      // so that l10n strings can be passed based on device locale.
    } catch (e) {
      // On error, only show error state if we have no data yet
      if (state.userProfile == null) {
        emit(state.copyWith(
          status: HomeStatus.error,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  /// Deletes an activity entry and refreshes the journey.
  Future<void> deleteActivity(String entryId) async {
    try {
      await _activityService.deleteEntry(entryId);
      final entries = await _activityService.getRecentEntries(limit: 20);
      emit(state.copyWith(activityEntries: entries));
    } catch (_) {}
  }

  /// Refreshes home data, forcing a fresh Firestore read for the profile.
  Future<void> refreshHome() async {
    _profileService.invalidateCache();
    await loadHome();
  }

  /// Schedules a 22:00 local notification if daily goal not yet met.
  /// Called from the UI layer with localized strings.
  void scheduleDailyGoalNotification({
    required String title,
    required String body,
  }) {
    final profile = state.userProfile;
    if (profile == null) return;
    final pagesReadToday = state.pagesReadToday;
    _dailyGoalNotificationService.scheduleIfNeeded(
      dailyGoal: profile.dailyGoalPages,
      pagesReadToday: pagesReadToday,
      title: title,
      body: body,
    );
  }

  /// Re-schedules reading reminders with localized strings.
  /// Called from the UI layer on app open to ensure correct language.
  Future<void> refreshReadingReminders({
    required String title,
    required String body,
  }) async {
    try {
      final prefs = await _notificationPreferencesService.getPreferences();
      await _readingReminderService.scheduleReminders(
        prefs: prefs,
        title: title,
        body: body,
      );
    } catch (_) {
      // Non-critical
    }
  }

  /// Re-schedules all active challenge notifications with localized strings.
  /// Called on every app resume to ensure notifications match device language.
  Future<void> refreshChallengeNotifications({
    required String lastDayTitle,
    required String midPointTitle,
    required String Function(Challenge) lastDayBodyBuilder,
    required String Function(Challenge) midPointBodyBuilder,
  }) async {
    try {
      final challenges = state.myChallenges;

      // Check if user has challenge notifications enabled
      final prefs = await _notificationPreferencesService.getPreferences();
      final shouldSchedule =
          prefs.enabled && prefs.challengeNotifications;

      for (final challenge in challenges) {
        // Always cancel old notifications first
        await _challengeNotificationService.cancelForChallenge(challenge.id);
        // Only re-schedule if preference allows
        if (shouldSchedule) {
          await _challengeNotificationService.scheduleForChallenge(
            challenge: challenge,
            lastDayTitle: lastDayTitle,
            lastDayBody: lastDayBodyBuilder(challenge),
            midPointTitle: midPointTitle,
            midPointBody: midPointBodyBuilder(challenge),
          );
        }
      }
    } catch (_) {
      // Non-critical
    }
  }

  /// Wraps an async int fetch so it returns 0 on failure instead of throwing.
  Future<int> _safeFetch(Future<int> Function() fetch) async {
    try {
      return await fetch();
    } catch (_) {
      return 0;
    }
  }

  /// Wraps an async list fetch so it returns empty on failure.
  Future<List<Challenge>> _safeFetchList(
      Future<List<Challenge>> Function() fetch) async {
    try {
      return await fetch();
    } catch (_) {
      return [];
    }
  }
}
