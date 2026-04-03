import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/models/activity_entry.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/focus_session_service.dart';
import '../../../core/services/focus_notification_service.dart';
import '../../../core/services/book_library_service.dart';
import '../../../core/services/challenge_service.dart';
import '../../../core/services/challenge_notification_service.dart';
import '../../../core/services/daily_goal_notification_service.dart';
import '../../../core/services/xp_service.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/services/remote_logger_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/models/user_book.dart';
import 'focus_state.dart';

class FocusCubit extends Cubit<FocusState> {
  final FocusSessionService _focusSessionService;
  final BookLibraryService _libraryService;
  final FocusNotificationService _notificationService;
  final ChallengeService _challengeService;
  final ChallengeNotificationService _challengeNotificationService;
  final XpService _xpService;
  final BadgeService _badgeService;
  final ActivityService _activityService;
  final UserProfileService _userProfileService;
  final DailyGoalNotificationService _dailyGoalNotificationService;
  Timer? _timer;
  int _notifTickCounter = 0;

  FocusCubit({
    required FocusSessionService focusSessionService,
    required BookLibraryService libraryService,
    required FocusNotificationService notificationService,
    required ChallengeService challengeService,
    required ChallengeNotificationService challengeNotificationService,
    required XpService xpService,
    required BadgeService badgeService,
    required ActivityService activityService,
    required UserProfileService userProfileService,
    required DailyGoalNotificationService dailyGoalNotificationService,
  })  : _focusSessionService = focusSessionService,
        _libraryService = libraryService,
        _notificationService = notificationService,
        _challengeService = challengeService,
        _challengeNotificationService = challengeNotificationService,
        _xpService = xpService,
        _badgeService = badgeService,
        _activityService = activityService,
        _userProfileService = userProfileService,
        _dailyGoalNotificationService = dailyGoalNotificationService,
        super(const FocusState());

  /// Loads recent sessions, today's focus minutes, and currently reading books.
  Future<void> loadInitialData() async {
    try {
      final recentSessions = await _focusSessionService.getRecentSessions();
      final todayMinutes = await _focusSessionService.getTotalFocusMinutesToday();
      final readingBooks = await _libraryService.getUserBooks(status: 'reading');

      emit(state.copyWith(
        recentSessions: recentSessions,
        todayMinutes: todayMinutes,
        readingBooks: readingBooks,
      ));

      // Check if the currently selected book is still in the reading list
      final currentBookStillReading = state.selectedBookId != null &&
          readingBooks.any((b) => b.bookId == state.selectedBookId);

      // Auto-select the most recently read book if none selected
      // or if the selected book is no longer in the reading list
      if (readingBooks.isNotEmpty &&
          (state.selectedBookId == null || !currentBookStillReading)) {
        final sorted = List<UserBook>.from(readingBooks)
          ..sort((a, b) {
            final aDate = a.lastReadDate ?? DateTime(2000);
            final bDate = b.lastReadDate ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });
        final lastRead = sorted.first;
        await selectBook(lastRead.bookId, lastRead.title);
      } else if (readingBooks.isEmpty && state.selectedBookId != null) {
        // No reading books left — clear the stale selection
        clearBook();
      }
    } catch (e) {
      emit(state.copyWith(
        status: FocusStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Returns the list of books currently being read (for book picker UI).
  Future<List<UserBook>> getReadingBooks() async {
    try {
      return await _libraryService.getUserBooks(status: 'reading');
    } catch (_) {
      return [];
    }
  }

  /// Selects a book for the focus session and loads its current page.
  Future<void> selectBook(String bookId, String bookTitle) async {
    emit(state.copyWith(
      selectedBookId: bookId,
      selectedBookTitle: bookTitle,
    ));
    try {
      final userBook = await _libraryService.getUserBook(bookId);
      if (userBook != null) {
        emit(state.copyWith(
          selectedBookCurrentPage: userBook.currentPage,
          selectedBookTotalPages: userBook.totalPages,
        ));
      }
    } catch (_) {}
  }

  /// Clears the currently selected book.
  void clearBook() {
    emit(state.copyWith(clearSelectedBook: true));
  }

  /// Sets the focus mode (free, pomodoro, goal).
  void setMode(FocusMode mode) {
    emit(state.copyWith(
      mode: mode,
      clearTargetDuration: mode != FocusMode.pomodoro,
      clearTargetPages: mode != FocusMode.goal,
    ));
  }

  /// Sets the target duration for pomodoro mode.
  void setTargetDuration(Duration duration) {
    emit(state.copyWith(targetDuration: duration));
  }

  /// Sets the target pages for goal mode.
  void setTargetPages(int pages) {
    emit(state.copyWith(targetPages: pages));
  }

  /// Starts the focus timer and creates a Firestore session.
  Future<void> startTimer() async {
    try {
      // Request permissions and create session in parallel
      await _notificationService.requestPermissions();
      final modeString = _modeToString(state.mode);
      final sessionId = await _focusSessionService.startSession(
        bookId: state.selectedBookId,
        bookTitle: state.selectedBookTitle,
        mode: modeString,
      );

      RemoteLoggerService.focus('Focus session started',
        bookTitle: state.selectedBookTitle);

      emit(state.copyWith(
        status: FocusStatus.running,
        sessionId: sessionId,
        elapsed: Duration.zero,
        pagesRead: 0,
        xpEarned: 0,
        clearError: true,
        isBreak: false,
        pomodoroCount: 0,
        targetDuration: state.mode == FocusMode.pomodoro
            ? const Duration(minutes: 25)
            : state.targetDuration,
      ));

      // Start timer immediately — don't wait for notification setup
      _notifTickCounter = 0;
      WakelockPlus.enable();
      _startPeriodicTimer();

      // Start foreground notification in background (non-blocking)
      _notificationService.startForegroundTimer(
        bookTitle: state.selectedBookTitle,
      ).catchError((_) {});
    } catch (e) {
      RemoteLoggerService.error('Focus session start failed', screen: 'focus', error: e);
      emit(state.copyWith(
        status: FocusStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Pauses the running timer.
  void pauseTimer() {
    if (state.status != FocusStatus.running) return;
    _timer?.cancel();
    try {
      _notificationService.cancelTimerNotification();
    } catch (_) {}
    RemoteLoggerService.focus('Focus session paused',
      bookTitle: state.selectedBookTitle);
    emit(state.copyWith(status: FocusStatus.paused));
  }

  /// Resumes a paused timer.
  void resumeTimer() {
    if (state.status != FocusStatus.paused) return;
    RemoteLoggerService.focus('Focus session resumed',
      bookTitle: state.selectedBookTitle);
    emit(state.copyWith(status: FocusStatus.running));
    _notifTickCounter = 0;
    _notificationService.updateTimerNotification(
      elapsed: state.elapsed,
      bookTitle: state.selectedBookTitle,
    );
    _startPeriodicTimer();
  }

  /// Stops the timer and ends the Firestore session.
  /// [pagesRead] can be provided for the session summary.
  Future<void> stopTimer({int pagesRead = 0}) async {
    _timer?.cancel();
    WakelockPlus.disable();
    try {
      _notificationService.cancelTimerNotification();
    } catch (_) {}

    if (state.sessionId == null) {
      emit(state.copyWith(status: FocusStatus.idle));
      return;
    }

    try {
      emit(state.copyWith(status: FocusStatus.completing));

      final completedSession = await _focusSessionService.endSession(
        state.sessionId!,
        pagesRead: pagesRead,
      );

      // Reload recent sessions and today's minutes
      final recentSessions = await _focusSessionService.getRecentSessions();
      final todayMinutes = await _focusSessionService.getTotalFocusMinutesToday();

      // Check calm mode — skip challenge/XP updates if active
      final profile = await _userProfileService.getProfile();
      final isCalmMode = profile?.calmMode ?? false;

      var totalXp = completedSession.xpEarned;

      if (!isCalmMode) {
        // Update challenge progress (minutes for sprint, pages if entered)
        final completedChallenges = await _challengeService.updateMyProgress(
          minutesRead: completedSession.durationMinutes,
          pagesRead: pagesRead,
        );
        for (final _ in completedChallenges) {
          final bonus = await _xpService.awardChallengeCompleteXp();
          totalXp += bonus;
        }

        // Cancel notifications for completed challenges
        if (completedChallenges.isNotEmpty) {
          await _challengeNotificationService
              .cancelForCompletedChallenges(completedChallenges);
        }
      }

      RemoteLoggerService.focus('Focus session completed',
        bookTitle: completedSession.bookTitle,
        durationMinutes: completedSession.durationMinutes,
        pagesRead: completedSession.pagesRead,
        xpEarned: totalXp);

      emit(state.copyWith(
        status: FocusStatus.completed,
        pagesRead: completedSession.pagesRead,
        xpEarned: totalXp,
        recentSessions: recentSessions,
        todayMinutes: todayMinutes,
      ));

      // Activity logging is deferred to saveSessionProgress() so we can
      // skip it when the user confirms no page progress was made.

      // Check for newly earned badges
      final newBadgeIds = await _badgeService.checkAndAwardBadges();
      if (newBadgeIds.isNotEmpty) {
        emit(state.copyWith(newlyEarnedBadgeIds: newBadgeIds));
      }
    } catch (e) {
      RemoteLoggerService.error('Focus session stop failed', screen: 'focus', error: e);
      emit(state.copyWith(
        status: FocusStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Saves page progress from the completed session, awards XP, and resets.
  Future<void> saveSessionProgress(int currentPageInput) async {
    final bookId = state.selectedBookId;
    if (bookId == null || currentPageInput <= 0) {
      resetTimer();
      return;
    }

    // Show saving/syncing overlay immediately
    emit(state.copyWith(status: FocusStatus.saving));

    try {
      final previousPage = state.selectedBookCurrentPage;
      final newPage = currentPageInput;
      final pageDelta = newPage - previousPage;

      // Update book progress in library
      await _libraryService.updateProgress(bookId: bookId, currentPage: newPage);

      // Update focus session with actual pages read
      if (state.sessionId != null && pageDelta > 0) {
        await _focusSessionService.updateSessionPages(
          state.sessionId!,
          pageDelta,
        );
      }

      // Check calm mode
      final profile = await _userProfileService.getProfile();
      final isCalmMode = profile?.calmMode ?? false;

      // Award XP for pages read (non-critical)
      int extraXp = 0;
      if (pageDelta > 0) {
        try {
          final result = await _xpService.awardPagesXp(pageDelta);
          extraXp = result.xpEarned;

          // Cancel daily goal notification if goal just reached
          if (result.dailyGoalReached) {
            _dailyGoalNotificationService.cancel();
          }

          if (!isCalmMode) {
            // Update challenge progress for pages
            final completed = await _challengeService.updateMyProgress(
              pagesRead: pageDelta,
            );
            for (final _ in completed) {
              final bonus = await _xpService.awardChallengeCompleteXp();
              extraXp += bonus;
            }
            if (completed.isNotEmpty) {
              await _challengeNotificationService
                  .cancelForCompletedChallenges(completed);
            }
          }
        } catch (_) {
          // Non-critical — page progress is already saved
        }
      }

      // Check if book is finished
      bool isBookFinished = false;
      if (state.selectedBookTotalPages > 0 &&
          newPage >= state.selectedBookTotalPages) {
        isBookFinished = true;
        await _libraryService.markAsFinished(bookId);
        try {
          final bookXp = await _xpService.awardBookFinishedXp();
          extraXp += bookXp;

          // Log book finished activity
          _activityService.log(ActivityEntry(
            id: '',
            type: ActivityType.bookFinished,
            timestamp: DateTime.now(),
            xpEarned: bookXp,
            bookTitle: state.selectedBookTitle,
          ));

          if (!isCalmMode) {
            final completedBook = await _challengeService.updateMyProgress(
              booksFinished: 1,
            );
            for (final _ in completedBook) {
              final bonus = await _xpService.awardChallengeCompleteXp();
              extraXp += bonus;
            }
            if (completedBook.isNotEmpty) {
              await _challengeNotificationService
                  .cancelForCompletedChallenges(completedBook);
            }
          }
        } catch (_) {
          // Non-critical — book is already marked as finished
        }
      }

      if (extraXp > 0) {
        emit(state.copyWith(xpEarned: state.xpEarned + extraXp));
      }

      // Check for newly earned badges after page progress
      try {
        final newBadgeIds = await _badgeService.checkAndAwardBadges();
        if (newBadgeIds.isNotEmpty) {
          for (final badgeId in newBadgeIds) {
            _activityService.log(ActivityEntry(
              id: '',
              type: ActivityType.badgeEarned,
              timestamp: DateTime.now(),
              badgeId: badgeId,
            ));
          }
          emit(state.copyWith(newlyEarnedBadgeIds: newBadgeIds));
        }
      } catch (_) {
        // Non-critical
      }

      // Log focus session activity for reading journey (only when pages were read)
      if (pageDelta > 0) {
        _activityService.log(ActivityEntry(
          id: '',
          type: ActivityType.focusSession,
          timestamp: DateTime.now(),
          xpEarned: state.xpEarned + extraXp,
          durationMinutes: state.elapsed.inMinutes,
          bookTitle: state.selectedBookTitle,
          pagesRead: pageDelta,
        ));
      }

      // Show book finished celebration before resetting
      if (isBookFinished) {
        emit(state.copyWith(
          status: FocusStatus.bookFinished,
          finishedBookTitle: state.selectedBookTitle,
          finishedBookXp: state.xpEarned + extraXp,
        ));
        return; // Don't reset — user will dismiss the celebration
      }
    } catch (_) {}

    resetTimer(updatedCurrentPage: currentPageInput);
  }

  /// Resets after a book is finished and reloads the reading list.
  Future<void> resetAfterBookFinished() async {
    _timer?.cancel();
    WakelockPlus.disable();
    emit(const FocusState().copyWith(
      recentSessions: state.recentSessions,
      todayMinutes: state.todayMinutes,
    ));
    await loadInitialData();
  }

  /// Discards session rewards when no page progress was made.
  /// Reverses the duration XP that was already awarded and resets without
  /// logging any activity to the reading journey.
  Future<void> discardSessionProgress() async {
    if (state.sessionId != null && state.xpEarned > 0) {
      try {
        await _focusSessionService.reverseSessionXp(
          state.sessionId!,
          state.xpEarned,
        );
      } catch (_) {
        // Non-critical — session is already saved
      }
    }
    resetTimer();
  }

  /// Resets the cubit state back to idle for a new session.
  /// Preserves the selected book so the user sees their last-read book.
  void resetTimer({int? updatedCurrentPage}) {
    _timer?.cancel();
    WakelockPlus.disable();
    emit(const FocusState().copyWith(
      recentSessions: state.recentSessions,
      todayMinutes: state.todayMinutes,
      readingBooks: state.readingBooks,
      selectedBookId: state.selectedBookId,
      selectedBookTitle: state.selectedBookTitle,
      selectedBookCurrentPage:
          updatedCurrentPage ?? state.selectedBookCurrentPage,
      selectedBookTotalPages: state.selectedBookTotalPages,
    ));
  }

  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == FocusStatus.running) {
        final newElapsed = state.elapsed + const Duration(seconds: 1);
        emit(state.copyWith(elapsed: newElapsed));

        // Update lock screen notification every 10 seconds
        _notifTickCounter++;
        if (_notifTickCounter >= 10) {
          _notifTickCounter = 0;
          _notificationService.updateTimerNotification(
            elapsed: newElapsed,
            bookTitle: state.selectedBookTitle,
          );
        }

        // Pomodoro cycle: work → break → work → ...
        if (state.mode == FocusMode.pomodoro &&
            state.targetDuration != null &&
            newElapsed >= state.targetDuration!) {
          if (!state.isBreak) {
            // Work → Break
            emit(state.copyWith(
              isBreak: true,
              elapsed: Duration.zero,
              targetDuration: const Duration(minutes: 5),
              pomodoroCount: state.pomodoroCount + 1,
            ));
          } else {
            // Break → Work
            emit(state.copyWith(
              isBreak: false,
              elapsed: Duration.zero,
              targetDuration: const Duration(minutes: 25),
            ));
          }
          _notifTickCounter = 0;
          _notificationService.updateTimerNotification(
            elapsed: Duration.zero,
            bookTitle: state.selectedBookTitle,
          );
          return;
        }
      }
    });
  }

  String _modeToString(FocusMode mode) {
    switch (mode) {
      case FocusMode.free:
        return 'free';
      case FocusMode.pomodoro:
        return 'pomodoro';
      case FocusMode.goal:
        return 'goal';
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    WakelockPlus.disable();
    return super.close();
  }
}
