import '../../../core/models/user_book.dart';
import '../../../core/models/book.dart';

enum BookDetailStatus { initial, loading, loaded, updating, removed, error }
enum CoverUploadStatus { idle, uploading, success, error }

class BookDetailState {
  final BookDetailStatus status;
  final UserBook? userBook;
  final Book? bookInfo;
  final String? errorMessage;
  final int lastXpAwarded;
  final List<String> newlyEarnedBadgeIds;
  final CoverUploadStatus coverUploadStatus;
  final List<String> allUserTags; // all tags the user has ever used

  const BookDetailState({
    this.status = BookDetailStatus.initial,
    this.userBook,
    this.bookInfo,
    this.errorMessage,
    this.lastXpAwarded = 0,
    this.newlyEarnedBadgeIds = const [],
    this.coverUploadStatus = CoverUploadStatus.idle,
    this.allUserTags = const [],
  });

  BookDetailState copyWith({
    BookDetailStatus? status,
    UserBook? userBook,
    Book? bookInfo,
    String? errorMessage,
    int? lastXpAwarded,
    List<String>? newlyEarnedBadgeIds,
    CoverUploadStatus? coverUploadStatus,
    List<String>? allUserTags,
  }) {
    return BookDetailState(
      status: status ?? this.status,
      userBook: userBook ?? this.userBook,
      bookInfo: bookInfo ?? this.bookInfo,
      errorMessage: errorMessage ?? this.errorMessage,
      lastXpAwarded: lastXpAwarded ?? this.lastXpAwarded,
      newlyEarnedBadgeIds: newlyEarnedBadgeIds ?? this.newlyEarnedBadgeIds,
      coverUploadStatus: coverUploadStatus ?? this.coverUploadStatus,
      allUserTags: allUserTags ?? this.allUserTags,
    );
  }
}
