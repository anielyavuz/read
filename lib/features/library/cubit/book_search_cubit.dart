import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/models/book.dart';
import '../../../core/services/book_library_service.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/services/remote_logger_service.dart';
import '../../../core/services/system_info_service.dart';
import 'book_search_state.dart';

class BookSearchCubit extends Cubit<BookSearchState> {
  final GoogleBooksService _googleBooksService;
  final BookLibraryService _libraryService;
  final SystemInfoService _systemInfoService;
  Timer? _debounceTimer;

  BookSearchCubit({
    required GoogleBooksService googleBooksService,
    required BookLibraryService libraryService,
    required SystemInfoService systemInfoService,
  })  : _googleBooksService = googleBooksService,
        _libraryService = libraryService,
        _systemInfoService = systemInfoService,
        super(const BookSearchState());

  void search(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      emit(const BookSearchState());
      return;
    }

    emit(state.copyWith(query: query, status: SearchStatus.searching));

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _googleBooksService.searchBooks(query);
        RemoteLoggerService.book('Book search',
          screen: 'book_search',
          details: {'query': query, 'result_count': results.length});

        if (results.isEmpty) {
          emit(state.copyWith(
            status: SearchStatus.empty,
            results: [],
          ));
        } else {
          emit(state.copyWith(
            status: SearchStatus.loaded,
            results: results,
          ));
        }
      } catch (e) {
        RemoteLoggerService.error('Book search failed', screen: 'book_search', error: e);
        emit(state.copyWith(
          status: SearchStatus.error,
          errorMessage: e.toString(),
        ));
      }
    });
  }

  Future<void> addToLibrary(Book book, String status) async {
    try {
      await _libraryService.addBookToLibrary(book: book, status: status);
      RemoteLoggerService.book('Book added to library',
        bookId: book.id, bookTitle: book.title,
        screen: 'book_search',
        details: {'status': status});
    } catch (e) {
      RemoteLoggerService.error('Add to library failed', screen: 'book_search', error: e);
      emit(state.copyWith(
        status: SearchStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<Book?> addManualBook({
    required String title,
    required String author,
    required int pageCount,
    required String status,
  }) async {
    try {
      final book = await _googleBooksService.saveCommunityBook(
        title: title,
        author: author,
        pageCount: pageCount,
      );
      await _libraryService.addBookToLibrary(book: book, status: status);
      RemoteLoggerService.book('Manual book added',
        bookId: book.id, bookTitle: title,
        screen: 'book_search',
        details: {'status': status, 'page_count': pageCount});
      return book;
    } catch (e) {
      RemoteLoggerService.error('Manual book add failed', screen: 'book_search', error: e);
      emit(state.copyWith(
        status: SearchStatus.error,
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  Future<void> scanBookCover(String imagePath) async {
    emit(state.copyWith(coverScanStatus: CoverScanStatus.scanning));

    try {
      final apiKey = await _systemInfoService.getGeminiApiKey();
      final modelName = await _systemInfoService.getGeminiModelName();

      if (apiKey.isEmpty) {
        emit(state.copyWith(coverScanStatus: CoverScanStatus.error));
        return;
      }

      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );

      final imageBytes = await File(imagePath).readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      const prompt = '''
Look at this image. If this is a book cover or a photo of a book:
1. Extract the book title
2. Extract the author name (if visible)
3. Estimate or extract the page count (if visible, otherwise null)

Return ONLY a JSON object: {"title": "...", "author": "...", "pageCount": null or number, "isBook": true}

If this is NOT a book image, return: {"isBook": false}
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          imagePart,
        ]),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        emit(state.copyWith(coverScanStatus: CoverScanStatus.error));
        return;
      }

      // Extract JSON from response (might be wrapped in markdown code block)
      String jsonStr = text.trim();
      if (jsonStr.contains('```')) {
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
        if (match != null) {
          jsonStr = match.group(1)!.trim();
        }
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final isBook = json['isBook'] as bool? ?? false;

      if (!isBook) {
        emit(state.copyWith(coverScanStatus: CoverScanStatus.notABook));
        return;
      }

      final result = CoverScanResult(
        title: json['title'] as String?,
        author: json['author'] as String?,
        pageCount: json['pageCount'] as int?,
      );

      RemoteLoggerService.book('Book cover scanned',
        bookTitle: result.title,
        screen: 'book_search');

      emit(state.copyWith(
        coverScanStatus: CoverScanStatus.success,
        coverScanResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(coverScanStatus: CoverScanStatus.error));
    }
  }

  void resetCoverScan() {
    emit(state.copyWith(
      coverScanStatus: CoverScanStatus.idle,
    ));
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    emit(const BookSearchState());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
