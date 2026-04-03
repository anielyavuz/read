import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class GoogleBooksService {
  final http.Client _client;
  final FirebaseFirestore _firestore;
  String? _cachedApiKey;

  GoogleBooksService({http.Client? client, FirebaseFirestore? firestore})
      : _client = client ?? http.Client(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _baseUrl = 'https://www.googleapis.com/books/v1';

  /// Fetch API key from Firestore: system/systemInfos → googleBooks.ApiKey
  Future<String> _getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey!;

    try {
      final doc = await _firestore.collection('system').doc('systemInfos').get();
      final data = doc.data();
      final googleBooks = data?['googleBooks'] as Map<String, dynamic>?;
      _cachedApiKey = googleBooks?['ApiKey'] as String? ?? '';
    } catch (_) {
      _cachedApiKey = '';
    }
    return _cachedApiKey!;
  }

  Future<List<Book>> searchBooks(String query, {int maxResults = 20}) async {
    if (query.trim().isEmpty) return [];

    final apiKey = await _getApiKey();
    final trimmed = query.trim();

    // Step 1: Search Google Books and Open Library in parallel
    final responses = await Future.wait([
      _executeGoogleSearch('intitle:$trimmed', apiKey, maxResults),
      _searchOpenLibrary(trimmed, maxResults),
    ]);

    final googleResults = responses[0];
    final openLibResults = responses[1];

    // Merge: Google Books first (better covers/metadata), then unique Open Library results
    final merged = _mergeResults(googleResults, openLibResults);
    if (merged.isNotEmpty) return merged;

    // Step 2: Search community catalog in Firestore
    return await _searchCommunityBooks(trimmed);
  }

  /// Merge two result lists, deduplicating by ISBN or normalized title+author.
  /// Enriches primary results with cover images from secondary when missing.
  List<Book> _mergeResults(List<Book> primary, List<Book> secondary) {
    if (primary.isEmpty) return secondary;
    if (secondary.isEmpty) return primary;

    // Build lookup maps from secondary for cover enrichment
    final secondaryByIsbn = <String, Book>{};
    final secondaryByTitle = <String, Book>{};
    for (final book in secondary) {
      if (book.isbn != null && book.isbn!.isNotEmpty) {
        secondaryByIsbn[book.isbn!] = book;
      }
      secondaryByTitle[_normalizeForDedup(book.title, book.authors)] = book;
    }

    // Enrich primary results: fill missing covers from secondary
    final merged = primary.map((book) {
      if (book.coverUrl != null && book.coverUrl!.isNotEmpty) return book;

      // Try to find matching secondary book with a cover
      Book? match;
      if (book.isbn != null && book.isbn!.isNotEmpty) {
        match = secondaryByIsbn[book.isbn!];
      }
      match ??= secondaryByTitle[_normalizeForDedup(book.title, book.authors)];

      if (match != null && match.coverUrl != null && match.coverUrl!.isNotEmpty) {
        return book.copyWith(coverUrl: match.coverUrl);
      }
      return book;
    }).toList();

    // Build dedup sets from primary
    final seenIsbns = <String>{};
    final seenTitles = <String>{};
    for (final book in primary) {
      if (book.isbn != null && book.isbn!.isNotEmpty) {
        seenIsbns.add(book.isbn!);
      }
      seenTitles.add(_normalizeForDedup(book.title, book.authors));
    }

    // Add unique secondary results
    for (final book in secondary) {
      if (book.isbn != null &&
          book.isbn!.isNotEmpty &&
          seenIsbns.contains(book.isbn!)) {
        continue;
      }
      final key = _normalizeForDedup(book.title, book.authors);
      if (seenTitles.contains(key)) continue;

      merged.add(book);
      if (book.isbn != null && book.isbn!.isNotEmpty) {
        seenIsbns.add(book.isbn!);
      }
      seenTitles.add(key);
    }

    return merged;
  }

  /// Normalize title + first author for dedup comparison
  String _normalizeForDedup(String title, List<String> authors) {
    final t = title.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9çğıöşüÇĞİÖŞÜ]'), '');
    final a = authors.isNotEmpty
        ? authors.first.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9çğıöşüÇĞİÖŞÜ]'), '')
        : '';
    return '$t|$a';
  }

  Future<List<Book>> _executeGoogleSearch(
      String query, String apiKey, int maxResults) async {
    final uri = Uri.parse('$_baseUrl/volumes').replace(queryParameters: {
      'q': query,
      'maxResults': '$maxResults',
      'printType': 'books',
      'orderBy': 'relevance',
      if (apiKey.isNotEmpty) 'key': apiKey,
    });

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final items = json['items'] as List?;
      if (items == null) return [];

      return items
          .cast<Map<String, dynamic>>()
          .map((item) => Book.fromGoogleBooks(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Search Open Library API as fallback
  Future<List<Book>> _searchOpenLibrary(String query, int maxResults) async {
    final uri = Uri.parse('https://openlibrary.org/search.json').replace(
      queryParameters: {
        'title': query,
        'limit': '$maxResults',
        'fields': 'key,title,author_name,cover_i,isbn,number_of_pages_median,subject,edition_key',
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = json['docs'] as List?;
      if (docs == null || docs.isEmpty) return [];

      return docs
          .cast<Map<String, dynamic>>()
          .map((doc) => Book.fromOpenLibrary(doc))
          .where((book) => book.title.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Search community-contributed books in Firestore
  Future<List<Book>> _searchCommunityBooks(String query) async {
    try {
      final queryLower = query.trim().toLowerCase();
      final words = queryLower.split(RegExp(r'\s+'));

      final snapshot = await _firestore
          .collection('communityBooks')
          .orderBy('titleLower')
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff'])
          .limit(10)
          .get();

      var results = snapshot.docs
          .map((doc) => Book.fromFirestore(doc))
          .toList();

      // Also search by author if few title results
      if (results.length < 3) {
        for (final word in words) {
          if (word.length < 3) continue;
          final authorSnap = await _firestore
              .collection('communityBooks')
              .orderBy('authorLower')
              .startAt([word])
              .endAt(['$word\uf8ff'])
              .limit(10)
              .get();

          final authorResults = authorSnap.docs
              .map((doc) => Book.fromFirestore(doc))
              .where((b) => !results.any((r) => r.id == b.id))
              .toList();
          results.addAll(authorResults);
          if (results.length >= 10) break;
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  /// Save a manually added book to the community catalog
  Future<Book> saveCommunityBook({
    required String title,
    required String author,
    required int pageCount,
  }) async {
    final docRef = await _firestore.collection('communityBooks').add({
      'title': title,
      'titleLower': title.toLowerCase(),
      'authors': [author],
      'authorLower': author.toLowerCase(),
      'pageCount': pageCount,
      'coverUrl': null,
      'isbn': null,
      'description': null,
      'categories': <String>[],
      'createdAt': DateTime.now().toIso8601String(),
    });

    return Book(
      id: docRef.id,
      title: title,
      authors: [author],
      pageCount: pageCount,
    );
  }

  Future<Book?> getBookById(String volumeId) async {
    final apiKey = await _getApiKey();
    final uri = Uri.parse('$_baseUrl/volumes/$volumeId').replace(
      queryParameters: {
        if (apiKey.isNotEmpty) 'key': apiKey,
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Book.fromGoogleBooks(json);
    } catch (_) {
      return null;
    }
  }
}
