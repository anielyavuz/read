import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/user_book.dart';
import '../../../core/services/book_library_service.dart';
import '../../../core/services/remote_logger_service.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final BookLibraryService _libraryService;

  LibraryCubit({
    required BookLibraryService libraryService,
  })  : _libraryService = libraryService,
        super(const LibraryState());

  Future<void> loadLibrary() async {
    // Only show loading spinner on the first load
    final isFirstLoad = state.status == LibraryStatus.initial;
    if (isFirstLoad) {
      emit(state.copyWith(status: LibraryStatus.loading));
    }

    try {
      final results = await Future.wait([
        _libraryService.getUserBooks(status: 'reading'),
        _libraryService.getUserBooks(status: 'finished'),
        _libraryService.getUserBooks(status: 'tbr'),
        _libraryService.getUserTags(),
      ]);

      emit(state.copyWith(
        status: LibraryStatus.loaded,
        readingBooks: results[0] as List<UserBook>,
        finishedBooks: results[1] as List<UserBook>,
        tbrBooks: results[2] as List<UserBook>,
        allTags: results[3] as List<String>,
      ));
    } catch (e) {
      RemoteLoggerService.error('Load library failed', screen: 'library', error: e);
      if (state.readingBooks.isEmpty) {
        emit(state.copyWith(
          status: LibraryStatus.error,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  void switchTab(String tab) {
    emit(state.copyWith(activeTab: tab));
  }

  void filterByTag(String? tag) {
    if (tag == null) {
      emit(state.copyWith(clearSelectedTag: true));
    } else {
      emit(state.copyWith(selectedTag: tag));
    }
  }

  Future<void> removeBook(String bookId) async {
    try {
      await _libraryService.removeBook(bookId);
      RemoteLoggerService.book('Book removed', bookId: bookId, screen: 'library');
      await loadLibrary();
    } catch (e) {
      RemoteLoggerService.error('Remove book failed', screen: 'library', error: e);
      emit(state.copyWith(
        status: LibraryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> startReading(String bookId) async {
    try {
      await _libraryService.markAsReading(bookId);
      RemoteLoggerService.book('Started reading', bookId: bookId, screen: 'library');
      await loadLibrary();
    } catch (e) {
      RemoteLoggerService.error('Start reading failed', screen: 'library', error: e);
      emit(state.copyWith(
        status: LibraryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> reorderTbrBooks(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final books = List<UserBook>.from(state.tbrBooks);
    final item = books.removeAt(oldIndex);
    books.insert(newIndex, item);

    // Optimistic update
    emit(state.copyWith(tbrBooks: books));

    try {
      await _libraryService.reorderTbrBooks(books);
    } catch (e) {
      // Revert on error
      await loadLibrary();
    }
  }
}
