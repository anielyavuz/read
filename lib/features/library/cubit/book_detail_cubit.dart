import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/activity_entry.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/book_library_service.dart';
import '../../../core/services/challenge_service.dart';
import '../../../core/services/challenge_notification_service.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/services/xp_service.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/services/remote_logger_service.dart';
import 'book_detail_state.dart';

class BookDetailCubit extends Cubit<BookDetailState> {
  final BookLibraryService _libraryService;
  final GoogleBooksService _googleBooksService;
  final XpService _xpService;
  final ChallengeService _challengeService;
  final ChallengeNotificationService _challengeNotificationService;
  final BadgeService _badgeService;
  final ActivityService _activityService;
  final UserProfileService _userProfileService;
  String? _bookId;

  BookDetailCubit({
    required BookLibraryService libraryService,
    required GoogleBooksService googleBooksService,
    required XpService xpService,
    required ChallengeService challengeService,
    required ChallengeNotificationService challengeNotificationService,
    required BadgeService badgeService,
    required ActivityService activityService,
    required UserProfileService userProfileService,
  })  : _libraryService = libraryService,
        _googleBooksService = googleBooksService,
        _xpService = xpService,
        _challengeService = challengeService,
        _challengeNotificationService = challengeNotificationService,
        _badgeService = badgeService,
        _activityService = activityService,
        _userProfileService = userProfileService,
        super(const BookDetailState());

  Future<void> loadBook(String bookId) async {
    _bookId = bookId;
    emit(state.copyWith(status: BookDetailStatus.loading));
    try {
      final userBook = await _libraryService.getUserBook(bookId);
      final bookInfo = await _googleBooksService.getBookById(bookId);
      final allTags = await _libraryService.getUserTags();

      emit(state.copyWith(
        status: BookDetailStatus.loaded,
        userBook: userBook,
        bookInfo: bookInfo,
        allUserTags: allTags,
      ));
    } catch (e) {
      RemoteLoggerService.error('Load book failed', screen: 'book_detail', error: e);
      emit(state.copyWith(
        status: BookDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updatePage(int newPage) async {
    if (_bookId == null) return;
    emit(state.copyWith(status: BookDetailStatus.updating));
    try {
      await _libraryService.updateProgress(bookId: _bookId!, currentPage: newPage);
      RemoteLoggerService.book('Page updated',
        bookId: _bookId, bookTitle: state.bookInfo?.title,
        screen: 'book_detail',
        details: {'to_page': newPage});

      // Library page updates are for manual corrections — no XP, no activity log.
      // XP is only earned through Focus Mode sessions.

      await loadBook(_bookId!);
    } catch (e) {
      RemoteLoggerService.error('Page update failed', screen: 'book_detail', error: e);
      emit(state.copyWith(
        status: BookDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> markAsFinished() async {
    if (_bookId == null) return;
    emit(state.copyWith(status: BookDetailStatus.updating));
    try {
      await _libraryService.markAsFinished(_bookId!);
      RemoteLoggerService.book('Book marked as finished',
        bookId: _bookId, bookTitle: state.bookInfo?.title,
        screen: 'book_detail');

      // Gamification: award XP, update challenges, log activity, check badges.
      // Wrapped separately so a failure here doesn't break the core update.
      int xpEarned = 0;
      List<String> newBadgeIds = [];
      try {
        xpEarned = await _xpService.awardBookFinishedXp();

        // Update genre-type challenge progress (skip in calm mode)
        final profile = await _userProfileService.getProfile();
        final isCalmMode = profile?.calmMode ?? false;
        if (!isCalmMode) {
          final completed = await _challengeService.updateMyProgress(
            booksFinished: 1,
          );
          for (final _ in completed) {
            final bonus = await _xpService.awardChallengeCompleteXp();
            xpEarned += bonus;
          }
          if (completed.isNotEmpty) {
            await _challengeNotificationService
                .cancelForCompletedChallenges(completed);
          }
        }
      } catch (_) {
        // Non-critical — book is already marked as finished
      }

      // Log book finished activity
      _activityService.log(ActivityEntry(
        id: '',
        type: ActivityType.bookFinished,
        timestamp: DateTime.now(),
        xpEarned: xpEarned,
        bookTitle: state.bookInfo?.title ?? state.userBook?.title,
      ));

      // Invalidate profile cache so HomeCubit gets fresh data
      _userProfileService.invalidateCache();

      await loadBook(_bookId!);
      try {
        newBadgeIds = await _badgeService.checkAndAwardBadges();
      } catch (_) {
        // Non-critical
      }
      emit(state.copyWith(lastXpAwarded: xpEarned, newlyEarnedBadgeIds: newBadgeIds));
    } catch (e) {
      RemoteLoggerService.error('Mark as finished failed', screen: 'book_detail', error: e);
      emit(state.copyWith(
        status: BookDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateTotalPages(int newTotalPages) async {
    if (_bookId == null) return;
    emit(state.copyWith(status: BookDetailStatus.updating));
    try {
      await _libraryService.updateTotalPages(
        bookId: _bookId!,
        totalPages: newTotalPages,
      );
      RemoteLoggerService.book('Total pages updated',
        bookId: _bookId, bookTitle: state.bookInfo?.title,
        screen: 'book_detail',
        details: {'total_pages': newTotalPages});
      await loadBook(_bookId!);
    } catch (e) {
      RemoteLoggerService.error('Update total pages failed', screen: 'book_detail', error: e);
      emit(state.copyWith(
        status: BookDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> removeFromLibrary() async {
    if (_bookId == null) return;
    emit(state.copyWith(status: BookDetailStatus.updating));
    try {
      await _libraryService.removeBook(_bookId!);
      RemoteLoggerService.book('Book removed from library',
        bookId: _bookId, bookTitle: state.bookInfo?.title,
        screen: 'book_detail');
      emit(state.copyWith(status: BookDetailStatus.removed));
    } catch (e) {
      RemoteLoggerService.error('Remove from library failed', screen: 'book_detail', error: e);
      emit(state.copyWith(
        status: BookDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> uploadCustomCover(ImageSource source) async {
    if (_bookId == null) return;
    emit(state.copyWith(coverUploadStatus: CoverUploadStatus.uploading));
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 600,
        imageQuality: 60,
      );

      if (pickedFile == null) {
        emit(state.copyWith(coverUploadStatus: CoverUploadStatus.idle));
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      // Check size: base64 adds ~33%, so 150KB raw -> ~200KB base64
      // If still too large after image_picker compression, reduce further
      final base64String = base64Encode(bytes);
      if (base64String.length > 270000) {
        // Re-pick with lower quality
        final smallerFile = await picker.pickImage(
          source: source,
          maxWidth: 300,
          maxHeight: 450,
          imageQuality: 40,
        );
        if (smallerFile == null) {
          emit(state.copyWith(coverUploadStatus: CoverUploadStatus.idle));
          return;
        }
        final smallerBytes = await smallerFile.readAsBytes();
        final smallerBase64 = base64Encode(smallerBytes);
        await _libraryService.updateCustomCover(
          bookId: _bookId!,
          base64Image: smallerBase64,
        );
      } else {
        await _libraryService.updateCustomCover(
          bookId: _bookId!,
          base64Image: base64String,
        );
      }

      await loadBook(_bookId!);
      emit(state.copyWith(coverUploadStatus: CoverUploadStatus.success));
    } catch (e) {
      emit(state.copyWith(coverUploadStatus: CoverUploadStatus.error));
    }
  }

  Future<void> removeCustomCover() async {
    if (_bookId == null) return;
    emit(state.copyWith(coverUploadStatus: CoverUploadStatus.uploading));
    try {
      await _libraryService.updateCustomCover(
        bookId: _bookId!,
        base64Image: null,
      );
      await loadBook(_bookId!);
      emit(state.copyWith(coverUploadStatus: CoverUploadStatus.success));
    } catch (e) {
      emit(state.copyWith(coverUploadStatus: CoverUploadStatus.error));
    }
  }

  Future<void> updateTags(List<String> tags) async {
    if (_bookId == null) return;
    try {
      await _libraryService.updateBookTags(bookId: _bookId!, tags: tags);
      RemoteLoggerService.book('Tags updated',
        bookId: _bookId, bookTitle: state.bookInfo?.title,
        screen: 'book_detail',
        details: {'tags': tags});
      // Refresh to get updated userBook + allUserTags
      await loadBook(_bookId!);
    } catch (e) {
      RemoteLoggerService.error('Update tags failed', screen: 'book_detail', error: e);
    }
  }

  Future<void> markAsReading() async {
    if (_bookId == null) return;
    emit(state.copyWith(status: BookDetailStatus.updating));
    try {
      await _libraryService.markAsReading(_bookId!);
      RemoteLoggerService.book('Book marked as reading',
        bookId: _bookId, bookTitle: state.bookInfo?.title,
        screen: 'book_detail');
      await loadBook(_bookId!);
    } catch (e) {
      RemoteLoggerService.error('Mark as reading failed', screen: 'book_detail', error: e);
      emit(state.copyWith(
        status: BookDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
