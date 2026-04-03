import '../../../core/models/book.dart';

enum SearchStatus { initial, searching, loaded, error, empty }

enum CoverScanStatus { idle, scanning, success, notABook, error }

class CoverScanResult {
  final String? title;
  final String? author;
  final int? pageCount;

  const CoverScanResult({this.title, this.author, this.pageCount});
}

class BookSearchState {
  final SearchStatus status;
  final List<Book> results;
  final String query;
  final String? errorMessage;
  final CoverScanStatus coverScanStatus;
  final CoverScanResult? coverScanResult;

  const BookSearchState({
    this.status = SearchStatus.initial,
    this.results = const [],
    this.query = '',
    this.errorMessage,
    this.coverScanStatus = CoverScanStatus.idle,
    this.coverScanResult,
  });

  BookSearchState copyWith({
    SearchStatus? status,
    List<Book>? results,
    String? query,
    String? errorMessage,
    CoverScanStatus? coverScanStatus,
    CoverScanResult? coverScanResult,
  }) {
    return BookSearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
      coverScanStatus: coverScanStatus ?? this.coverScanStatus,
      coverScanResult: coverScanResult,
    );
  }
}
