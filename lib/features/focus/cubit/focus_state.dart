import '../../../core/models/focus_session.dart';
import '../../../core/models/user_book.dart';

enum FocusStatus { idle, running, paused, completing, completed, saving, bookFinished, error }

enum FocusMode { free, pomodoro, goal }

class FocusState {
  final FocusStatus status;
  final FocusMode mode;
  final Duration elapsed;
  final Duration? targetDuration;
  final int? targetPages;
  final String? selectedBookId;
  final String? selectedBookTitle;
  final int selectedBookCurrentPage;
  final int selectedBookTotalPages;
  final String? sessionId;
  final int pagesRead;
  final int xpEarned;
  final String? errorMessage;
  final List<FocusSession> recentSessions;
  final int todayMinutes;
  final List<UserBook> readingBooks;
  final List<String> newlyEarnedBadgeIds;
  final bool isBreak;
  final int pomodoroCount;
  final String? finishedBookTitle;
  final int finishedBookXp;

  const FocusState({
    this.status = FocusStatus.idle,
    this.mode = FocusMode.free,
    this.elapsed = Duration.zero,
    this.targetDuration,
    this.targetPages,
    this.selectedBookId,
    this.selectedBookTitle,
    this.selectedBookCurrentPage = 0,
    this.selectedBookTotalPages = 0,
    this.sessionId,
    this.pagesRead = 0,
    this.xpEarned = 0,
    this.errorMessage,
    this.recentSessions = const [],
    this.todayMinutes = 0,
    this.readingBooks = const [],
    this.newlyEarnedBadgeIds = const [],
    this.isBreak = false,
    this.pomodoroCount = 0,
    this.finishedBookTitle,
    this.finishedBookXp = 0,
  });

  FocusState copyWith({
    FocusStatus? status,
    FocusMode? mode,
    Duration? elapsed,
    Duration? targetDuration,
    bool clearTargetDuration = false,
    int? targetPages,
    bool clearTargetPages = false,
    String? selectedBookId,
    bool clearSelectedBook = false,
    String? selectedBookTitle,
    int? selectedBookCurrentPage,
    int? selectedBookTotalPages,
    String? sessionId,
    bool clearSessionId = false,
    int? pagesRead,
    int? xpEarned,
    String? errorMessage,
    bool clearError = false,
    List<FocusSession>? recentSessions,
    int? todayMinutes,
    List<UserBook>? readingBooks,
    List<String>? newlyEarnedBadgeIds,
    bool clearNewlyEarnedBadgeIds = false,
    bool? isBreak,
    int? pomodoroCount,
    String? finishedBookTitle,
    bool clearFinishedBookTitle = false,
    int? finishedBookXp,
  }) {
    return FocusState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      elapsed: elapsed ?? this.elapsed,
      targetDuration: clearTargetDuration
          ? null
          : (targetDuration ?? this.targetDuration),
      targetPages:
          clearTargetPages ? null : (targetPages ?? this.targetPages),
      selectedBookId: clearSelectedBook
          ? null
          : (selectedBookId ?? this.selectedBookId),
      selectedBookTitle: clearSelectedBook
          ? null
          : (selectedBookTitle ?? this.selectedBookTitle),
      selectedBookCurrentPage: clearSelectedBook
          ? 0
          : (selectedBookCurrentPage ?? this.selectedBookCurrentPage),
      selectedBookTotalPages: clearSelectedBook
          ? 0
          : (selectedBookTotalPages ?? this.selectedBookTotalPages),
      sessionId:
          clearSessionId ? null : (sessionId ?? this.sessionId),
      pagesRead: pagesRead ?? this.pagesRead,
      xpEarned: xpEarned ?? this.xpEarned,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      recentSessions: recentSessions ?? this.recentSessions,
      todayMinutes: todayMinutes ?? this.todayMinutes,
      readingBooks: readingBooks ?? this.readingBooks,
      newlyEarnedBadgeIds: clearNewlyEarnedBadgeIds ? const [] : (newlyEarnedBadgeIds ?? this.newlyEarnedBadgeIds),
      isBreak: isBreak ?? this.isBreak,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      finishedBookTitle: clearFinishedBookTitle
          ? null
          : (finishedBookTitle ?? this.finishedBookTitle),
      finishedBookXp: finishedBookXp ?? this.finishedBookXp,
    );
  }
}
