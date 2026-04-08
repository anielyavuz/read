import 'package:get_it/get_it.dart';
import 'ai_chat_service.dart';
import 'auth_service.dart';
import 'user_profile_service.dart';
import 'notification_service.dart';
import 'notification_preferences_service.dart';
import 'google_books_service.dart';
import 'book_library_service.dart';
import 'book_note_service.dart';
import 'focus_session_service.dart';
import 'focus_notification_service.dart';
import 'xp_service.dart';
import 'badge_service.dart';
import 'friendship_service.dart';
import 'inbox_service.dart';
import 'system_info_service.dart';
import 'reader_profile_repository.dart';
import 'reader_profile_service.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/home/cubit/home_cubit.dart';
import '../../features/library/cubit/library_cubit.dart';
import '../../features/library/cubit/book_search_cubit.dart';
import '../../features/library/cubit/book_detail_cubit.dart';
import '../../features/focus/cubit/focus_cubit.dart';
import '../../features/focus/cubit/book_notes_cubit.dart';
import 'activity_service.dart';
import 'league_service.dart';
import 'challenge_service.dart';
import 'challenge_notification_service.dart';
import 'daily_goal_notification_service.dart';
import 'reading_reminder_service.dart';
import '../../features/league/cubit/league_cubit.dart';
import '../../features/profile/cubit/notification_settings_cubit.dart';
import '../../features/profile/cubit/profile_cubit.dart';
import '../../features/discover/cubit/discover_cubit.dart';
import '../../features/discover/cubit/challenge_detail_cubit.dart';
import '../../features/discover/cubit/create_challenge_cubit.dart';
import '../../features/friends/cubit/friends_cubit.dart';
import '../../features/inbox/cubit/inbox_cubit.dart';
import '../../features/reader_profile/cubit/reader_profile_cubit.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Services
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<UserProfileService>(() => UserProfileService());
  getIt.registerLazySingleton<InboxService>(() => InboxService());
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(
      profileService: getIt<UserProfileService>(),
      inboxService: getIt<InboxService>(),
    ),
  );
  getIt.registerLazySingleton<GoogleBooksService>(() => GoogleBooksService());
  getIt.registerLazySingleton<BookLibraryService>(() => BookLibraryService());
  getIt.registerLazySingleton<LeagueService>(() => LeagueService());
  getIt.registerLazySingleton<XpService>(
    () => XpService(leagueService: getIt<LeagueService>()),
  );
  getIt.registerLazySingleton<BadgeService>(() => BadgeService());
  getIt.registerLazySingleton<NotificationPreferencesService>(
    () => NotificationPreferencesService(),
  );
  getIt.registerLazySingleton<FriendshipService>(() => FriendshipService());
  getIt.registerLazySingleton<ActivityService>(() => ActivityService());
  getIt.registerLazySingleton<ReadingReminderService>(
    () => ReadingReminderService(),
  );
  getIt.registerLazySingleton<DailyGoalNotificationService>(
    () => DailyGoalNotificationService(),
  );
  // Cubits
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(
      authService: getIt<AuthService>(),
      profileService: getIt<UserProfileService>(),
      notificationService: getIt<NotificationService>(),
      readingReminderService: getIt<ReadingReminderService>(),
    ),
  );
  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(
      profileService: getIt<UserProfileService>(),
      friendshipService: getIt<FriendshipService>(),
      inboxService: getIt<InboxService>(),
      activityService: getIt<ActivityService>(),
      readerProfileRepository: getIt<ReaderProfileRepository>(),
      challengeService: getIt<ChallengeService>(),
      notificationService: getIt<NotificationService>(),
      dailyGoalNotificationService: getIt<DailyGoalNotificationService>(),
      readingReminderService: getIt<ReadingReminderService>(),
      notificationPreferencesService: getIt<NotificationPreferencesService>(),
      challengeNotificationService: getIt<ChallengeNotificationService>(),
    ),
  );
  getIt.registerFactory<LibraryCubit>(
    () => LibraryCubit(libraryService: getIt<BookLibraryService>()),
  );
  getIt.registerFactory<BookSearchCubit>(
    () => BookSearchCubit(
      googleBooksService: getIt<GoogleBooksService>(),
      libraryService: getIt<BookLibraryService>(),
      systemInfoService: getIt<SystemInfoService>(),
    ),
  );
  getIt.registerFactory<BookDetailCubit>(
    () => BookDetailCubit(
      libraryService: getIt<BookLibraryService>(),
      googleBooksService: getIt<GoogleBooksService>(),
      xpService: getIt<XpService>(),
      challengeService: getIt<ChallengeService>(),
      challengeNotificationService: getIt<ChallengeNotificationService>(),
      badgeService: getIt<BadgeService>(),
      activityService: getIt<ActivityService>(),
      userProfileService: getIt<UserProfileService>(),
    ),
  );
  getIt.registerLazySingleton<BookNoteService>(() => BookNoteService());
  getIt.registerLazySingleton<FocusSessionService>(
    () => FocusSessionService(leagueService: getIt<LeagueService>()),
  );
  getIt.registerLazySingleton<FocusNotificationService>(
    () => FocusNotificationService(),
  );
  getIt.registerFactory<FocusCubit>(
    () => FocusCubit(
      focusSessionService: getIt<FocusSessionService>(),
      libraryService: getIt<BookLibraryService>(),
      notificationService: getIt<FocusNotificationService>(),
      challengeService: getIt<ChallengeService>(),
      challengeNotificationService: getIt<ChallengeNotificationService>(),
      xpService: getIt<XpService>(),
      badgeService: getIt<BadgeService>(),
      activityService: getIt<ActivityService>(),
      userProfileService: getIt<UserProfileService>(),
      dailyGoalNotificationService: getIt<DailyGoalNotificationService>(),
    ),
  );
  getIt.registerFactory<BookNotesCubit>(
    () => BookNotesCubit(noteService: getIt<BookNoteService>()),
  );
  getIt.registerFactory<LeagueCubit>(
    () => LeagueCubit(
      leagueService: getIt<LeagueService>(),
      friendshipService: getIt<FriendshipService>(),
    ),
  );
  getIt.registerFactory<NotificationSettingsCubit>(
    () => NotificationSettingsCubit(
      service: getIt<NotificationPreferencesService>(),
      reminderService: getIt<ReadingReminderService>(),
      challengeNotifService: getIt<ChallengeNotificationService>(),
      challengeService: getIt<ChallengeService>(),
    ),
  );

  // Challenge
  getIt.registerLazySingleton<ChallengeService>(() => ChallengeService());
  getIt.registerLazySingleton<ChallengeNotificationService>(
    () => ChallengeNotificationService(),
  );
  getIt.registerFactory<DiscoverCubit>(
    () => DiscoverCubit(challengeService: getIt<ChallengeService>()),
  );
  getIt.registerFactory<ChallengeDetailCubit>(
    () => ChallengeDetailCubit(
      challengeService: getIt<ChallengeService>(),
      xpService: getIt<XpService>(),
      challengeNotificationService: getIt<ChallengeNotificationService>(),
      notificationPrefsService: getIt<NotificationPreferencesService>(),
    ),
  );
  getIt.registerFactory<CreateChallengeCubit>(
    () => CreateChallengeCubit(
      challengeService: getIt<ChallengeService>(),
      inboxService: getIt<InboxService>(),
    ),
  );

  // Friends
  getIt.registerFactory<FriendsCubit>(
    () => FriendsCubit(friendshipService: getIt<FriendshipService>()),
  );

  // Inbox
  getIt.registerFactory<InboxCubit>(
    () => InboxCubit(
      inboxService: getIt<InboxService>(),
      challengeService: getIt<ChallengeService>(),
    ),
  );

  // Profile
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      profileService: getIt<UserProfileService>(),
      badgeService: getIt<BadgeService>(),
      challengeService: getIt<ChallengeService>(),
      challengeNotificationService: getIt<ChallengeNotificationService>(),
    ),
  );

  // AI & Reader Profile
  getIt.registerLazySingleton<SystemInfoService>(() => SystemInfoService());
  getIt.registerLazySingleton<AiChatService>(
    () => AiChatService(systemInfoService: getIt<SystemInfoService>()),
  );
  getIt.registerLazySingleton<ReaderProfileRepository>(
    () => ReaderProfileRepository(),
  );
  getIt.registerLazySingleton<ReaderProfileService>(
    () => ReaderProfileService(
      aiChatService: getIt<AiChatService>(),
    ),
  );
  getIt.registerFactory<ReaderProfileCubit>(
    () => ReaderProfileCubit(
      service: getIt<ReaderProfileService>(),
      repository: getIt<ReaderProfileRepository>(),
      googleBooksService: getIt<GoogleBooksService>(),
      bookLibraryService: getIt<BookLibraryService>(),
    ),
  );
}
