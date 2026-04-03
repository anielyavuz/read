import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final int pageCount;
  final String? isbn;
  final String? description;
  final List<String> categories;

  const Book({
    required this.id,
    required this.title,
    this.authors = const [],
    this.coverUrl,
    this.pageCount = 0,
    this.isbn,
    this.description,
    this.categories = const [],
  });

  factory Book.fromGoogleBooks(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final identifiers = volumeInfo['industryIdentifiers'] as List?;

    String? coverUrl = imageLinks?['thumbnail'] as String?;
    // Google Books returns http URLs, upgrade to https
    if (coverUrl != null && coverUrl.startsWith('http://')) {
      coverUrl = coverUrl.replaceFirst('http://', 'https://');
    }

    String? isbn;
    if (identifiers != null && identifiers.isNotEmpty) {
      // Prefer ISBN_13 over ISBN_10
      final isbn13 = identifiers.cast<Map<String, dynamic>>().where((i) => i['type'] == 'ISBN_13');
      if (isbn13.isNotEmpty) {
        isbn = isbn13.first['identifier'] as String?;
      } else {
        isbn = identifiers.first['identifier'] as String?;
      }
    }

    return Book(
      id: json['id'] as String,
      title: volumeInfo['title'] as String? ?? '',
      authors: (volumeInfo['authors'] as List?)?.cast<String>() ?? [],
      coverUrl: coverUrl,
      pageCount: volumeInfo['pageCount'] as int? ?? 0,
      isbn: isbn,
      description: volumeInfo['description'] as String?,
      categories: (volumeInfo['categories'] as List?)?.cast<String>() ?? [],
    );
  }

  factory Book.fromOpenLibrary(Map<String, dynamic> doc) {
    final coverId = doc['cover_i'] as int?;
    final coverUrl = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
        : null;

    final isbns = doc['isbn'] as List?;
    String? isbn;
    if (isbns != null && isbns.isNotEmpty) {
      // Prefer 13-digit ISBN
      isbn = isbns.cast<String>().firstWhere(
            (i) => i.length == 13,
            orElse: () => isbns.first as String,
          );
    }

    return Book(
      id: 'ol_${doc['key'] ?? doc['edition_key']?.first ?? ''}',
      title: doc['title'] as String? ?? '',
      authors: (doc['author_name'] as List?)?.cast<String>() ?? [],
      coverUrl: coverUrl,
      pageCount: doc['number_of_pages_median'] as int? ?? 0,
      isbn: isbn,
      description: null,
      categories: (doc['subject'] as List?)?.cast<String>().take(5).toList() ?? [],
    );
  }

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      authors: List<String>.from(data['authors'] ?? []),
      coverUrl: data['coverUrl'],
      pageCount: data['pageCount'] ?? 0,
      isbn: data['isbn'],
      description: data['description'],
      categories: List<String>.from(data['categories'] ?? []),
    );
  }

  Book copyWith({String? coverUrl, int? pageCount}) {
    return Book(
      id: id,
      title: title,
      authors: authors,
      coverUrl: coverUrl ?? this.coverUrl,
      pageCount: pageCount ?? this.pageCount,
      isbn: isbn,
      description: description,
      categories: categories,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'authors': authors,
      'coverUrl': coverUrl,
      'pageCount': pageCount,
      'isbn': isbn,
      'description': description,
      'categories': categories,
    };
  }
}
