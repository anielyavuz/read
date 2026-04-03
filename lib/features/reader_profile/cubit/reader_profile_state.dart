import '../../../core/models/reader_profile.dart';

enum ReaderProfileStatus {
  initial,
  quizInProgress,
  generating,
  generated,
  error,
  loading,
  loaded,
}

class ReaderProfileState {
  final ReaderProfileStatus status;
  final int currentQuestion; // 0..3
  final String q1Answer;
  final List<String> q2Answers; // multi-select chips
  final String q4Answer; // reading habit chip
  final String q5Answer; // emotional preference chip
  final ReaderProfile? profile;
  final String? errorMessage;

  /// Tracks book actions: book title -> status ("finished", "tbr", or "not_interested")
  final Map<String, String> bookActions;

  /// All previously recommended book titles (for excluding from new recs)
  final List<String> allRecommendedTitles;

  /// Titles the user marked as "not interested" (sent to Gemini as disliked)
  final List<String> dislikedTitles;

  /// Whether new recommendations are being loaded
  final bool loadingMoreRecs;

  const ReaderProfileState({
    this.status = ReaderProfileStatus.initial,
    this.currentQuestion = 0,
    this.q1Answer = '',
    this.q2Answers = const [],
    this.q4Answer = '',
    this.q5Answer = '',
    this.profile,
    this.errorMessage,
    this.bookActions = const {},
    this.allRecommendedTitles = const [],
    this.dislikedTitles = const [],
    this.loadingMoreRecs = false,
  });

  /// How many of the current batch of books have been acted on
  int get actedBookCount {
    if (profile == null) return 0;
    return profile!.recommendedBooks
        .where((b) => bookActions.containsKey(b.title))
        .length;
  }

  bool get allBooksActed =>
      profile != null &&
      profile!.recommendedBooks.isNotEmpty &&
      actedBookCount >= profile!.recommendedBooks.length;

  ReaderProfileState copyWith({
    ReaderProfileStatus? status,
    int? currentQuestion,
    String? q1Answer,
    List<String>? q2Answers,
    String? q4Answer,
    String? q5Answer,
    ReaderProfile? profile,
    String? errorMessage,
    Map<String, String>? bookActions,
    List<String>? allRecommendedTitles,
    List<String>? dislikedTitles,
    bool? loadingMoreRecs,
  }) {
    return ReaderProfileState(
      status: status ?? this.status,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      q1Answer: q1Answer ?? this.q1Answer,
      q2Answers: q2Answers ?? this.q2Answers,
      q4Answer: q4Answer ?? this.q4Answer,
      q5Answer: q5Answer ?? this.q5Answer,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      bookActions: bookActions ?? this.bookActions,
      allRecommendedTitles: allRecommendedTitles ?? this.allRecommendedTitles,
      dislikedTitles: dislikedTitles ?? this.dislikedTitles,
      loadingMoreRecs: loadingMoreRecs ?? this.loadingMoreRecs,
    );
  }
}
