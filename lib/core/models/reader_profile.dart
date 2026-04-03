import 'package:cloud_firestore/cloud_firestore.dart';

class ReaderProfile {
  final String archetypeName;
  final String archetypeDescription;
  final List<String> preferredGenres;
  final String preferredTone;
  final List<String> avoidGenres;
  final List<RecommendedBook> recommendedBooks;
  final int readingSpeedMinutes;
  final ProfileScore profileScore;
  final QuizAnswers quizAnswers;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Book titles user marked as "not interested" — persisted for Gemini exclusion.
  final List<String> dislikedTitles;

  /// Per-book action state: title → "finished" | "tbr" | "not_interested".
  final Map<String, String> bookActions;

  const ReaderProfile({
    required this.archetypeName,
    required this.archetypeDescription,
    required this.preferredGenres,
    required this.preferredTone,
    required this.avoidGenres,
    required this.recommendedBooks,
    required this.readingSpeedMinutes,
    required this.profileScore,
    required this.quizAnswers,
    required this.createdAt,
    required this.updatedAt,
    this.dislikedTitles = const [],
    this.bookActions = const {},
  });

  factory ReaderProfile.fromJson(Map<String, dynamic> json) {
    return ReaderProfile(
      archetypeName: json['archetypeName'] ?? '',
      archetypeDescription: json['archetypeDescription'] ?? '',
      preferredGenres: List<String>.from(json['preferredGenres'] ?? []),
      preferredTone: json['preferredTone'] ?? '',
      avoidGenres: List<String>.from(json['avoidGenres'] ?? []),
      recommendedBooks: (json['recommendedBooks'] as List?)
              ?.map((e) =>
                  RecommendedBook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      readingSpeedMinutes: json['readingSpeedMinutes'] ?? 30,
      profileScore: json['profileScore'] != null
          ? ProfileScore.fromJson(json['profileScore'] as Map<String, dynamic>)
          : const ProfileScore(),
      quizAnswers: json['quizAnswers'] != null
          ? QuizAnswers.fromJson(json['quizAnswers'] as Map<String, dynamic>)
          : const QuizAnswers(),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
      dislikedTitles: List<String>.from(json['dislikedTitles'] ?? []),
      bookActions: Map<String, String>.from(json['bookActions'] ?? {}),
    );
  }

  factory ReaderProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReaderProfile.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'archetypeName': archetypeName,
      'archetypeDescription': archetypeDescription,
      'preferredGenres': preferredGenres,
      'preferredTone': preferredTone,
      'avoidGenres': avoidGenres,
      'recommendedBooks': recommendedBooks.map((e) => e.toJson()).toList(),
      'readingSpeedMinutes': readingSpeedMinutes,
      'profileScore': profileScore.toJson(),
      'quizAnswers': quizAnswers.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dislikedTitles': dislikedTitles,
      'bookActions': bookActions,
    };
  }

  ReaderProfile copyWith({
    String? archetypeName,
    String? archetypeDescription,
    List<String>? preferredGenres,
    String? preferredTone,
    List<String>? avoidGenres,
    List<RecommendedBook>? recommendedBooks,
    int? readingSpeedMinutes,
    ProfileScore? profileScore,
    QuizAnswers? quizAnswers,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? dislikedTitles,
    Map<String, String>? bookActions,
  }) {
    return ReaderProfile(
      archetypeName: archetypeName ?? this.archetypeName,
      archetypeDescription: archetypeDescription ?? this.archetypeDescription,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      preferredTone: preferredTone ?? this.preferredTone,
      avoidGenres: avoidGenres ?? this.avoidGenres,
      recommendedBooks: recommendedBooks ?? this.recommendedBooks,
      readingSpeedMinutes: readingSpeedMinutes ?? this.readingSpeedMinutes,
      profileScore: profileScore ?? this.profileScore,
      quizAnswers: quizAnswers ?? this.quizAnswers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dislikedTitles: dislikedTitles ?? this.dislikedTitles,
      bookActions: bookActions ?? this.bookActions,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'archetypeName': archetypeName,
      'archetypeDescription': archetypeDescription,
      'preferredGenres': preferredGenres,
      'preferredTone': preferredTone,
      'avoidGenres': avoidGenres,
      'recommendedBooks': recommendedBooks.map((e) => e.toJson()).toList(),
      'readingSpeedMinutes': readingSpeedMinutes,
      'profileScore': profileScore.toJson(),
      'quizAnswers': quizAnswers.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'dislikedTitles': dislikedTitles,
      'bookActions': bookActions,
    };
  }
}

class RecommendedBook {
  final String title;
  final String author;
  final String reason;

  const RecommendedBook({
    required this.title,
    required this.author,
    required this.reason,
  });

  factory RecommendedBook.fromJson(Map<String, dynamic> json) {
    return RecommendedBook(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'reason': reason,
    };
  }
}

class ProfileScore {
  final int characterFocus;
  final int plotFocus;
  final int atmosphereFocus;
  final int paceSlow;

  const ProfileScore({
    this.characterFocus = 0,
    this.plotFocus = 0,
    this.atmosphereFocus = 0,
    this.paceSlow = 0,
  });

  factory ProfileScore.fromJson(Map<String, dynamic> json) {
    return ProfileScore(
      characterFocus: json['characterFocus'] ?? 0,
      plotFocus: json['plotFocus'] ?? 0,
      atmosphereFocus: json['atmosfereFocus'] ?? json['atmosphereFocus'] ?? 0,
      paceSlow: json['paceSlow'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'characterFocus': characterFocus,
      'plotFocus': plotFocus,
      'atmosphereFocus': atmosphereFocus,
      'paceSlow': paceSlow,
    };
  }
}

class QuizAnswers {
  final String q1;
  final String q2;
  final String q3;
  final String q4;
  final String q5;

  const QuizAnswers({
    this.q1 = '',
    this.q2 = '',
    this.q3 = '',
    this.q4 = '',
    this.q5 = '',
  });

  factory QuizAnswers.fromJson(Map<String, dynamic> json) {
    return QuizAnswers(
      q1: json['q1'] ?? '',
      q2: json['q2'] ?? '',
      q3: json['q3'] ?? '',
      q4: json['q4'] ?? '',
      q5: json['q5'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'q1': q1,
      'q2': q2,
      'q3': q3,
      'q4': q4,
      'q5': q5,
    };
  }
}
