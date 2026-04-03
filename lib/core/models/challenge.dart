import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType { readAlong, sprint, genre, pages }

enum ChallengeStatus { active, completed, upcoming }

ChallengeType challengeTypeFromString(String value) {
  switch (value) {
    case 'read_along':
      return ChallengeType.readAlong;
    case 'sprint':
      return ChallengeType.sprint;
    case 'genre':
      return ChallengeType.genre;
    case 'pages':
      return ChallengeType.pages;
    default:
      return ChallengeType.sprint;
  }
}

String challengeTypeToString(ChallengeType type) {
  switch (type) {
    case ChallengeType.readAlong:
      return 'read_along';
    case ChallengeType.sprint:
      return 'sprint';
    case ChallengeType.genre:
      return 'genre';
    case ChallengeType.pages:
      return 'pages';
  }
}

class Challenge {
  final String id;
  final ChallengeType type;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final String? bookId;
  final String? bookTitle;
  final DateTime startDate;
  final DateTime endDate;
  final int? targetPages;
  final int? targetBooks;
  final int? targetMinutes;
  final int maxParticipants;
  final int currentParticipants;
  final bool isPublic;

  const Challenge({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    this.bookId,
    this.bookTitle,
    required this.startDate,
    required this.endDate,
    this.targetPages,
    this.targetBooks,
    this.targetMinutes,
    this.maxParticipants = 30,
    this.currentParticipants = 0,
    this.isPublic = true,
  });

  ChallengeStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return ChallengeStatus.upcoming;
    if (now.isAfter(endDate)) return ChallengeStatus.completed;
    return ChallengeStatus.active;
  }

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      type: challengeTypeFromString(data['type'] ?? 'sprint'),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      bookId: data['bookId'],
      bookTitle: data['bookTitle'],
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetPages: data['targetPages'],
      targetBooks: data['targetBooks'],
      targetMinutes: data['targetMinutes'],
      maxParticipants: data['maxParticipants'] ?? 30,
      currentParticipants: data['currentParticipants'] ?? 0,
      isPublic: data['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': challengeTypeToString(type),
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetPages': targetPages,
      'targetBooks': targetBooks,
      'targetMinutes': targetMinutes,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'isPublic': isPublic,
    };
  }

  Challenge copyWith({
    String? id,
    ChallengeType? type,
    String? title,
    String? description,
    String? creatorId,
    String? creatorName,
    String? bookId,
    String? bookTitle,
    DateTime? startDate,
    DateTime? endDate,
    int? targetPages,
    int? targetBooks,
    int? targetMinutes,
    int? maxParticipants,
    int? currentParticipants,
    bool? isPublic,
  }) {
    return Challenge(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetPages: targetPages ?? this.targetPages,
      targetBooks: targetBooks ?? this.targetBooks,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

class ChallengeParticipant {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int progress;
  final int rank;
  final DateTime joinedAt;
  final DateTime lastUpdateAt;

  const ChallengeParticipant({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.progress = 0,
    this.rank = 0,
    required this.joinedAt,
    required this.lastUpdateAt,
  });

  factory ChallengeParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeParticipant(
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      progress: data['progress'] ?? 0,
      rank: data['rank'] ?? 0,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdateAt:
          (data['lastUpdateAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'progress': progress,
      'rank': rank,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastUpdateAt': Timestamp.fromDate(lastUpdateAt),
    };
  }
}
