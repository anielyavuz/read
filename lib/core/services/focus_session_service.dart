import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/focus_session.dart';
import 'league_service.dart';

class FocusSessionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LeagueService _leagueService;

  FocusSessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required LeagueService leagueService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _leagueService = leagueService;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('focusSessions');

  /// Starts a new focus session and returns the created session ID.
  Future<String> startSession({
    String? bookId,
    String? bookTitle,
    String mode = 'free',
  }) async {
    if (_uid == null) throw Exception('No authenticated user');

    final now = DateTime.now();
    final docRef = _sessionsRef(_uid!).doc();

    final session = FocusSession(
      id: docRef.id,
      userId: _uid!,
      bookId: bookId,
      bookTitle: bookTitle,
      startTime: now,
      mode: mode,
      createdAt: now,
    );

    await docRef.set(session.toFirestore());
    return docRef.id;
  }

  /// Ends an active session: sets endTime, calculates duration and XP,
  /// updates user profile stats.
  Future<FocusSession> endSession(
    String sessionId, {
    int pagesRead = 0,
  }) async {
    if (_uid == null) throw Exception('No authenticated user');

    final docRef = _sessionsRef(_uid!).doc(sessionId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('Session not found');

    final session = FocusSession.fromFirestore(doc);
    final now = DateTime.now();
    final durationMinutes = now.difference(session.startTime).inMinutes;
    final xpEarned = _calculateXp(durationMinutes);

    await docRef.update({
      'endTime': Timestamp.fromDate(now),
      'durationMinutes': durationMinutes,
      'pagesRead': pagesRead,
      'completed': true,
      'xpEarned': xpEarned,
    });

    // Update user profile stats + streak
    final userDocRef = _firestore.collection('users').doc(_uid);
    final userSnap = await userDocRef.get();
    final userData = userSnap.data() ?? {};
    final isCalmMode = userData['calmMode'] == true;

    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final storedDate = userData['pagesReadTodayDate'] as String?;
    final isSameDay = storedDate == todayStr;

    if (isCalmMode) {
      // Calm mode: save tracking stats only, no XP/streak/league
      final trackingUpdates = <String, dynamic>{
        'focusMinutesTotal': FieldValue.increment(durationMinutes),
        'lastReadDate': Timestamp.fromDate(now),
        'pagesRead': FieldValue.increment(pagesRead),
        'pagesReadTodayDate': todayStr,
      };
      if (isSameDay) {
        trackingUpdates['pagesReadToday'] = FieldValue.increment(pagesRead);
      } else {
        trackingUpdates['pagesReadToday'] = pagesRead;
      }
      await userDocRef.update(trackingUpdates);
      await docRef.update({'xpEarned': 0});
    } else {
      final lastReadDate = (userData['lastReadDate'] as Timestamp?)?.toDate();
      final currentStreak = userData['streakDays'] as int? ?? 0;
      final dailyGoalPages = userData['dailyGoalPages'] as int? ?? 20;

      final today = DateTime(now.year, now.month, now.day);

      // Calculate what pagesReadToday will be after this update
      final previousPagesToday =
          isSameDay ? (userData['pagesReadToday'] as int? ?? 0) : 0;
      final newPagesToday = previousPagesToday + pagesRead;

      // Streak logic: only advance when daily goal is reached
      bool streakUpdated = false;
      int newStreak = currentStreak;
      final goalJustReached = previousPagesToday < dailyGoalPages &&
          newPagesToday >= dailyGoalPages;

      if (goalJustReached) {
        if (lastReadDate == null) {
          newStreak = 1;
        } else {
          final lastDay = DateTime(
            lastReadDate.year,
            lastReadDate.month,
            lastReadDate.day,
          );
          if (lastDay.isBefore(today)) {
            final yesterday = today.subtract(const Duration(days: 1));
            newStreak = (lastDay == yesterday || lastDay == today)
                ? currentStreak + 1
                : 1;
          } else {
            newStreak = currentStreak + 1;
          }
        }
        streakUpdated = true;
      }

      // Reset xpThisWeek if a new Monday-to-Sunday week has started
      await _leagueService.resetWeeklyXpIfNeeded();

      final updates = <String, dynamic>{
        'focusMinutesTotal': FieldValue.increment(durationMinutes),
        'lastReadDate': Timestamp.fromDate(now),
        'pagesRead': FieldValue.increment(pagesRead),
        'xpTotal': FieldValue.increment(xpEarned),
        'xpThisWeek': FieldValue.increment(xpEarned),
        'pagesReadTodayDate': todayStr,
      };

      if (isSameDay) {
        updates['pagesReadToday'] = FieldValue.increment(pagesRead);
      } else {
        updates['pagesReadToday'] = pagesRead;
      }

      if (streakUpdated) {
        updates['streakDays'] = newStreak;
      }

      await userDocRef.update(updates);
      await _leagueService.addXpToLeague(xpEarned);
    }

    // Return the completed session
    final updatedDoc = await docRef.get();
    return FocusSession.fromFirestore(updatedDoc);
  }

  /// Reverses XP awarded for a focus session when no page progress was made.
  /// Sets session xpEarned to 0 and decrements user/league XP.
  Future<void> reverseSessionXp(String sessionId, int totalXp) async {
    if (_uid == null || totalXp <= 0) return;

    // Mark session as zero XP
    await _sessionsRef(_uid!).doc(sessionId).update({'xpEarned': 0});

    // Check calm mode — if active, XP was never awarded
    final userDocRef = _firestore.collection('users').doc(_uid);
    final userSnap = await userDocRef.get();
    final isCalmMode = (userSnap.data() ?? {})['calmMode'] == true;

    if (!isCalmMode) {
      await userDocRef.update({
        'xpTotal': FieldValue.increment(-totalXp),
        'xpThisWeek': FieldValue.increment(-totalXp),
      });
      await _leagueService.removeXpFromLeague(totalXp);
    }
  }

  /// Updates the pagesRead field of a completed focus session.
  Future<void> updateSessionPages(String sessionId, int pagesRead) async {
    if (_uid == null) return;
    await _sessionsRef(_uid!).doc(sessionId).update({
      'pagesRead': pagesRead,
    });
  }

  /// Returns recent focus sessions for the current user, ordered by createdAt descending.
  Future<List<FocusSession>> getRecentSessions({int limit = 10}) async {
    if (_uid == null) return [];

    final snapshot = await _sessionsRef(_uid!)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => FocusSession.fromFirestore(doc))
        .toList();
  }

  /// Returns all completed focus sessions from today for the current user.
  Future<List<FocusSession>> getTodaySessions() async {
    if (_uid == null) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _sessionsRef(_uid!)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FocusSession.fromFirestore(doc))
        .where((session) => session.completed)
        .toList();
  }

  /// Returns total focus minutes completed today for the current user.
  Future<int> getTotalFocusMinutesToday() async {
    final sessions = await getTodaySessions();
    return sessions.fold<int>(0, (total, s) => total + s.durationMinutes);
  }

  /// Returns total pages read this week from the user profile.
  /// This is more reliable than summing focus session pagesRead,
  /// because pages can also be tracked via the book detail screen.
  Future<int> getWeeklyPagesRead() async {
    if (_uid == null) return 0;
    try {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(monday.year, monday.month, monday.day);

      final snapshot = await _sessionsRef(_uid!)
          .where('completed', isEqualTo: true)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();

      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['pagesRead'] as int?) ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Calculates XP earned based on duration using CLAUDE.md rules:
  /// 15 min = 15 XP, 30 min = 30 XP, 60+ min = 50 XP.
  /// Sessions under 15 min earn proportionally (1 XP per minute).
  int _calculateXp(int durationMinutes) {
    if (durationMinutes >= 60) return 50;
    if (durationMinutes >= 30) return 30;
    if (durationMinutes >= 15) return 15;
    return durationMinutes; // 1 XP per minute for short sessions
  }
}
