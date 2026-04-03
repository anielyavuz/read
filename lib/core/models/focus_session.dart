import 'package:cloud_firestore/cloud_firestore.dart';

class FocusSession {
  final String id;
  final String userId;
  final String? bookId;
  final String? bookTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int pagesRead;
  final String mode; // "free" | "pomodoro" | "goal"
  final bool completed;
  final int xpEarned;
  final DateTime createdAt;

  const FocusSession({
    required this.id,
    required this.userId,
    this.bookId,
    this.bookTitle,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.pagesRead = 0,
    this.mode = 'free',
    this.completed = false,
    this.xpEarned = 0,
    required this.createdAt,
  });

  factory FocusSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FocusSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookId: data['bookId'],
      bookTitle: data['bookTitle'],
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      durationMinutes: data['durationMinutes'] ?? 0,
      pagesRead: data['pagesRead'] ?? 0,
      mode: data['mode'] ?? 'free',
      completed: data['completed'] ?? false,
      xpEarned: data['xpEarned'] ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationMinutes': durationMinutes,
      'pagesRead': pagesRead,
      'mode': mode,
      'completed': completed,
      'xpEarned': xpEarned,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
