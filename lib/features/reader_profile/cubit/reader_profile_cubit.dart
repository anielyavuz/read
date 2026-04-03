import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/book.dart';
import '../../../core/services/reader_profile_service.dart';
import '../../../core/services/reader_profile_repository.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/services/book_library_service.dart';
import '../../../core/services/remote_logger_service.dart';
import 'reader_profile_state.dart';

class ReaderProfileCubit extends Cubit<ReaderProfileState> {
  final ReaderProfileService _service;
  final ReaderProfileRepository _repository;
  final GoogleBooksService _googleBooksService;
  final BookLibraryService _bookLibraryService;

  ReaderProfileCubit({
    required ReaderProfileService service,
    required ReaderProfileRepository repository,
    required GoogleBooksService googleBooksService,
    required BookLibraryService bookLibraryService,
  })  : _service = service,
        _repository = repository,
        _googleBooksService = googleBooksService,
        _bookLibraryService = bookLibraryService,
        super(const ReaderProfileState());

  void setQ1(String answer) {
    emit(state.copyWith(
      q1Answer: answer,
      status: ReaderProfileStatus.quizInProgress,
    ));
  }

  /// Toggle a Q2 chip (multi-select).
  void toggleQ2(String answer) {
    final current = List<String>.from(state.q2Answers);
    if (current.contains(answer)) {
      current.remove(answer);
    } else {
      current.add(answer);
    }
    emit(state.copyWith(
      q2Answers: current,
      status: ReaderProfileStatus.quizInProgress,
    ));
  }

  void setQ4(String answer) {
    emit(state.copyWith(
      q4Answer: answer,
      status: ReaderProfileStatus.quizInProgress,
    ));
  }

  void setQ5(String answer) {
    emit(state.copyWith(
      q5Answer: answer,
      status: ReaderProfileStatus.quizInProgress,
    ));
  }

  void nextQuestion() {
    if (state.currentQuestion < 3) {
      emit(state.copyWith(currentQuestion: state.currentQuestion + 1));
    }
  }

  void previousQuestion() {
    if (state.currentQuestion > 0) {
      emit(state.copyWith(currentQuestion: state.currentQuestion - 1));
    }
  }

  Future<void> generateProfile() async {
    emit(state.copyWith(status: ReaderProfileStatus.generating));
    try {
      // Gather library context for richer Gemini prompt
      List<String> finishedBooks = [];
      int totalPages = 0;
      try {
        final books = await _bookLibraryService.getUserBooks(status: 'finished');
        finishedBooks = books.map((b) => '${b.title} - ${b.authors.join(', ')}').toList();
        final allBooks = await _bookLibraryService.getUserBooks();
        totalPages = allBooks.fold<int>(0, (sum, b) => sum + b.currentPage);
      } catch (_) {}

      final profile = await _service.generateProfile(
        q1Answer: state.q1Answer,
        q2Answer: state.q2Answers.join(', '),
        q3Answer: '',
        q4Answer: state.q4Answer,
        q5Answer: state.q5Answer,
        userFinishedBooks: finishedBooks,
        totalPagesRead: totalPages,
      );
      await _repository.setReaderProfile(profile);
      RemoteLoggerService.userAction('Reader profile generated',
        screen: 'reader_profile',
        details: {'archetype': profile.archetypeName});
      final titles = profile.recommendedBooks.map((b) => b.title).toList();
      emit(state.copyWith(
        status: ReaderProfileStatus.generated,
        profile: profile,
        allRecommendedTitles: titles,
        bookActions: {},
      ));
    } catch (e) {
      RemoteLoggerService.error('Generate reader profile failed', screen: 'reader_profile', error: e);
      emit(state.copyWith(
        status: ReaderProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadExistingProfile() async {
    emit(state.copyWith(status: ReaderProfileStatus.loading));
    try {
      final profile = await _repository.getReaderProfile();
      if (profile != null) {
        final titles = profile.recommendedBooks.map((b) => b.title).toList();
        emit(state.copyWith(
          status: ReaderProfileStatus.loaded,
          profile: profile,
          allRecommendedTitles: titles,
          bookActions: profile.bookActions,
          dislikedTitles: profile.dislikedTitles,
        ));
      } else {
        emit(state.copyWith(status: ReaderProfileStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ReaderProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> retry() async {
    await generateProfile();
  }

  /// Pre-fill quiz answers from existing profile for update flow.
  Future<void> prefillFromExistingProfile() async {
    try {
      final profile = await _repository.getReaderProfile();
      if (profile != null && profile.quizAnswers.q1.isNotEmpty) {
        final qa = profile.quizAnswers;
        // Q2 stored as comma-separated, split back to list
        final q2List = qa.q2.isNotEmpty
            ? qa.q2.split(', ').where((s) => s.isNotEmpty).toList()
            : <String>[];
        emit(state.copyWith(
          status: ReaderProfileStatus.quizInProgress,
          q1Answer: qa.q1,
          q2Answers: q2List,
          q4Answer: qa.q4,
          q5Answer: qa.q5,
          currentQuestion: 0,
        ));
      }
    } catch (_) {}
  }

  /// Mark a book as not interested (won't be recommended again)
  Future<void> markNotInterested(String bookTitle) async {
    final updatedActions = Map<String, String>.from(state.bookActions);
    updatedActions[bookTitle] = 'not_interested';
    final updatedDisliked = [...state.dislikedTitles, bookTitle];
    emit(state.copyWith(
      bookActions: updatedActions,
      dislikedTitles: updatedDisliked,
    ));

    // Persist to Firestore
    _persistFeedback(updatedActions, updatedDisliked);

    // Auto-fetch 1 new recommendation to replace it
    await _fetchAndAppendRecommendations(1);
  }

  /// Save a recommended book to user's library with status "finished" or "tbr"
  Future<void> saveBookToLibrary(String bookTitle, String bookAuthor, String status) async {
    // Mark immediately in state (optimistic update)
    final updatedActions = Map<String, String>.from(state.bookActions);
    updatedActions[bookTitle] = status;
    emit(state.copyWith(bookActions: updatedActions));

    // Save book to library — if it fails, revert the action so the book reappears
    final saved = await _saveBookInBackground(bookTitle, bookAuthor, status);

    if (saved) {
      // Persist feedback only after the book is successfully saved to library
      _persistFeedback(updatedActions, state.dislikedTitles);

      // Auto-fetch 1 new recommendation
      await _fetchAndAppendRecommendations(1);
    } else {
      // Revert optimistic update — remove the action so the book reappears
      final revertedActions = Map<String, String>.from(state.bookActions);
      revertedActions.remove(bookTitle);
      emit(state.copyWith(bookActions: revertedActions));
    }
  }

  /// Persist bookActions & dislikedTitles into the ReaderProfile on Firestore.
  void _persistFeedback(Map<String, String> actions, List<String> disliked) {
    final profile = state.profile;
    if (profile == null) return;
    final updated = profile.copyWith(
      bookActions: actions,
      dislikedTitles: disliked,
      updatedAt: DateTime.now(),
    );
    // Fire-and-forget
    _repository.setReaderProfile(updated).catchError((_) {});
  }

  /// Find the best matching book from search results by comparing titles.
  /// Prefers exact match, then "starts with", then "contains", then first result.
  Book _bestMatch(List<Book> results, String targetTitle) {
    final normalised = targetTitle.trim().toLowerCase();

    // 1. Exact title match
    for (final b in results) {
      if (b.title.trim().toLowerCase() == normalised) return b;
    }

    // 2. Starts with the target title (catches subtitle variations)
    for (final b in results) {
      if (b.title.trim().toLowerCase().startsWith(normalised)) return b;
    }

    // 3. Shortest title that contains the target (avoids "... Üzerine Yazılar" style)
    final containing = results
        .where((b) => b.title.trim().toLowerCase().contains(normalised))
        .toList()
      ..sort((a, b) => a.title.length.compareTo(b.title.length));
    if (containing.isNotEmpty) return containing.first;

    // 4. Fallback: first result
    return results.first;
  }

  Future<bool> _saveBookInBackground(String bookTitle, String bookAuthor, String status) async {
    try {
      final query = '$bookTitle $bookAuthor';
      final results = await _googleBooksService.searchBooks(query, maxResults: 5);

      Book book;
      if (results.isNotEmpty) {
        book = _bestMatch(results, bookTitle);
      } else {
        book = await _googleBooksService.saveCommunityBook(
          title: bookTitle,
          author: bookAuthor,
          pageCount: 0,
        );
      }

      await _bookLibraryService.addBookToLibrary(book: book, status: status);

      if (status == 'finished' && book.pageCount > 0) {
        await _bookLibraryService.markAsFinished(book.id);
      }

      RemoteLoggerService.book('recommendation_saved_to_library',
        bookTitle: bookTitle,
        screen: 'reader_profile',
        details: {'status': status, 'author': bookAuthor},
      );
      return true;
    } catch (e) {
      RemoteLoggerService.error(
        'Failed to save recommended book to library',
        screen: 'reader_profile',
        error: e,
      );
      return false;
    }
  }

  /// Load 3 more recommendations from Gemini (manual button)
  Future<void> loadMoreRecommendations() async {
    await _fetchAndAppendRecommendations(3);
  }

  /// Fetch N new recommendations and append them to the list
  Future<void> _fetchAndAppendRecommendations(int count) async {
    if (state.profile == null) return;
    emit(state.copyWith(loadingMoreRecs: true));

    try {
      final newBooks = await _service.generateMoreRecommendations(
        profile: state.profile!,
        previouslyRecommendedTitles: state.allRecommendedTitles,
        dislikedTitles: state.dislikedTitles,
        count: count,
      );

      if (newBooks.isEmpty) {
        emit(state.copyWith(loadingMoreRecs: false));
        return;
      }

      // Append new books to existing list
      final allBooks = [
        ...state.profile!.recommendedBooks,
        ...newBooks,
      ];

      final updatedProfile = state.profile!.copyWith(
        recommendedBooks: allBooks,
        updatedAt: DateTime.now(),
      );

      // Save updated profile to Firestore
      await _repository.setReaderProfile(updatedProfile);

      final updatedTitles = [
        ...state.allRecommendedTitles,
        ...newBooks.map((b) => b.title),
      ];

      emit(state.copyWith(
        profile: updatedProfile,
        allRecommendedTitles: updatedTitles,
        loadingMoreRecs: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadingMoreRecs: false,
        errorMessage: e.toString(),
      ));
    }
  }

}
