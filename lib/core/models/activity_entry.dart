import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of activity that appear on the reading journey path.
enum ActivityType {
  focusSession,
  pageProgress,
  bookFinished,
  badgeEarned,
  streakMilestone,
  challengeCompleted,
  levelUp,
}

/// A single entry in the user's reading journey timeline.
class ActivityEntry {
  final String id;
  final ActivityType type;
  final DateTime timestamp;
  final int xpEarned;

  // Focus session fields
  final int? durationMinutes;
  final String? bookTitle;
  final int? pagesRead;

  // Badge fields
  final String? badgeId;

  // Streak fields
  final int? streakDays;

  // Challenge fields
  final String? challengeTitle;

  // Companion level fields
  final int? newLevel;

  const ActivityEntry({
    required this.id,
    required this.type,
    required this.timestamp,
    this.xpEarned = 0,
    this.durationMinutes,
    this.bookTitle,
    this.pagesRead,
    this.badgeId,
    this.streakDays,
    this.challengeTitle,
    this.newLevel,
  });

  factory ActivityEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityEntry(
      id: doc.id,
      type: ActivityType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ActivityType.focusSession,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      xpEarned: data['xpEarned'] ?? 0,
      durationMinutes: data['durationMinutes'],
      bookTitle: data['bookTitle'],
      pagesRead: data['pagesRead'],
      badgeId: data['badgeId'],
      streakDays: data['streakDays'],
      challengeTitle: data['challengeTitle'],
      newLevel: data['newLevel'],
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'xpEarned': xpEarned,
    };
    if (durationMinutes != null) map['durationMinutes'] = durationMinutes;
    if (bookTitle != null) map['bookTitle'] = bookTitle;
    if (pagesRead != null) map['pagesRead'] = pagesRead;
    if (badgeId != null) map['badgeId'] = badgeId;
    if (streakDays != null) map['streakDays'] = streakDays;
    if (challengeTitle != null) map['challengeTitle'] = challengeTitle;
    if (newLevel != null) map['newLevel'] = newLevel;
    return map;
  }
}
