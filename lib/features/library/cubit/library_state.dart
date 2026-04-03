import '../../../core/models/user_book.dart';

enum LibraryStatus { initial, loading, loaded, error }

class LibraryState {
  final LibraryStatus status;
  final List<UserBook> readingBooks;
  final List<UserBook> finishedBooks;
  final List<UserBook> tbrBooks;
  final String activeTab; // "reading" | "finished" | "tbr"
  final String? errorMessage;
  final List<String> allTags; // all unique tags across library
  final String? selectedTag; // null = show all

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.readingBooks = const [],
    this.finishedBooks = const [],
    this.tbrBooks = const [],
    this.activeTab = 'reading',
    this.errorMessage,
    this.allTags = const [],
    this.selectedTag,
  });

  /// Filtered lists based on selectedTag
  List<UserBook> get filteredReadingBooks => _filterByTag(readingBooks);
  List<UserBook> get filteredFinishedBooks => _filterByTag(finishedBooks);
  List<UserBook> get filteredTbrBooks => _filterByTag(tbrBooks);

  List<UserBook> _filterByTag(List<UserBook> books) {
    if (selectedTag == null) return books;
    return books.where((b) => b.tags.contains(selectedTag)).toList();
  }

  LibraryState copyWith({
    LibraryStatus? status,
    List<UserBook>? readingBooks,
    List<UserBook>? finishedBooks,
    List<UserBook>? tbrBooks,
    String? activeTab,
    String? errorMessage,
    List<String>? allTags,
    String? selectedTag,
    bool clearSelectedTag = false,
  }) {
    return LibraryState(
      status: status ?? this.status,
      readingBooks: readingBooks ?? this.readingBooks,
      finishedBooks: finishedBooks ?? this.finishedBooks,
      tbrBooks: tbrBooks ?? this.tbrBooks,
      activeTab: activeTab ?? this.activeTab,
      errorMessage: errorMessage ?? this.errorMessage,
      allTags: allTags ?? this.allTags,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
    );
  }
}
