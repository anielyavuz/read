import 'package:cloud_firestore/cloud_firestore.dart';

class UserBook {
  final String bookId;
  final String status; // "reading" | "finished" | "tbr"
  final int currentPage;
  final int totalPages;
  final DateTime? startDate;
  final DateTime? finishDate;
  final DateTime? lastReadDate;
  final int totalReadingMinutes;
  final double? quizScore;

  // Denormalized book info
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final String? customCoverBase64;
  final int? sortOrder; // TBR priority order (1, 2, 3...)
  final List<String> tags; // user-defined tags (e.g. "Fiction", "Self-Help")

  const UserBook({
    required this.bookId,
    required this.status,
    this.currentPage = 0,
    this.totalPages = 0,
    this.startDate,
    this.finishDate,
    this.lastReadDate,
    this.totalReadingMinutes = 0,
    this.quizScore,
    required this.title,
    this.authors = const [],
    this.coverUrl,
    this.customCoverBase64,
    this.sortOrder,
    this.tags = const [],
  });

  double get progressPercent => totalPages > 0 ? currentPage / totalPages : 0;

  factory UserBook.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBook(
      bookId: doc.id,
      status: data['status'] ?? 'tbr',
      currentPage: data['currentPage'] ?? 0,
      totalPages: data['totalPages'] ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      finishDate: (data['finishDate'] as Timestamp?)?.toDate(),
      lastReadDate: (data['lastReadDate'] as Timestamp?)?.toDate(),
      totalReadingMinutes: data['totalReadingMinutes'] ?? 0,
      quizScore: (data['quizScore'] as num?)?.toDouble(),
      title: data['title'] ?? '',
      authors: List<String>.from(data['authors'] ?? []),
      coverUrl: data['coverUrl'],
      customCoverBase64: data['customCoverBase64'],
      sortOrder: data['sortOrder'] as int?,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status': status,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'finishDate': finishDate != null ? Timestamp.fromDate(finishDate!) : null,
      'lastReadDate': lastReadDate != null ? Timestamp.fromDate(lastReadDate!) : null,
      'totalReadingMinutes': totalReadingMinutes,
      'quizScore': quizScore,
      'title': title,
      'authors': authors,
      'coverUrl': coverUrl,
      if (customCoverBase64 != null) 'customCoverBase64': customCoverBase64,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'tags': tags,
    };
  }

  UserBook copyWith({
    String? status,
    int? currentPage,
    int? totalPages,
    DateTime? finishDate,
    DateTime? lastReadDate,
    int? totalReadingMinutes,
    double? quizScore,
    String? customCoverBase64,
    bool clearCustomCover = false,
    int? sortOrder,
    List<String>? tags,
  }) {
    return UserBook(
      bookId: bookId,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      startDate: startDate,
      finishDate: finishDate ?? this.finishDate,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      totalReadingMinutes: totalReadingMinutes ?? this.totalReadingMinutes,
      quizScore: quizScore ?? this.quizScore,
      title: title,
      authors: authors,
      coverUrl: coverUrl,
      customCoverBase64: clearCustomCover ? null : (customCoverBase64 ?? this.customCoverBase64),
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
    );
  }
}
