import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/league.dart';

class LeagueService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  LeagueService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Checks if the current week has changed since the user's last XP update.
  /// If so, resets xpThisWeek to 0 and stores the new weekId.
  /// Must be called before any xpThisWeek increment.
  Future<void> resetWeeklyXpIfNeeded() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final weekId = getCurrentWeekId();
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();
    final storedWeekId = doc.data()?['xpWeekId'] as String?;

    if (storedWeekId != weekId) {
      await userRef.update({
        'xpThisWeek': 0,
        'xpWeekId': weekId,
      });
    }
  }

  /// Returns the current ISO week ID, e.g. "2026-W10".
  String getCurrentWeekId() {
    final now = DateTime.now().toUtc();
    // ISO week calculation
    final dayOfYear = now.difference(DateTime.utc(now.year, 1, 1)).inDays + 1;
    final weekday = now.weekday; // 1=Mon, 7=Sun
    final weekNumber =
        ((dayOfYear - weekday + 10) / 7).floor();

    if (weekNumber < 1) {
      // Last week of previous year
      final prevYearLastDay = DateTime.utc(now.year - 1, 12, 31);
      final prevDayOfYear =
          prevYearLastDay.difference(DateTime.utc(now.year - 1, 1, 1)).inDays +
              1;
      final prevWeekday = prevYearLastDay.weekday;
      final prevWeek =
          ((prevDayOfYear - prevWeekday + 10) / 7).floor();
      return '${now.year - 1}-W${prevWeek.toString().padLeft(2, '0')}';
    } else if (weekNumber > 52) {
      // Check if it's actually week 1 of next year
      final dec28 = DateTime.utc(now.year, 12, 28);
      final dec28DayOfYear =
          dec28.difference(DateTime.utc(now.year, 1, 1)).inDays + 1;
      final maxWeek =
          ((dec28DayOfYear - dec28.weekday + 10) / 7).floor();
      if (weekNumber > maxWeek) {
        return '${now.year + 1}-W01';
      }
    }

    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Returns sorted leaderboard for a given week, limited to 30 participants.
  Future<List<LeagueParticipant>> getLeaderboard(String weekId) async {
    try {
      final snapshot = await _firestore
          .collection('leagues')
          .doc(weekId)
          .collection('participants')
          .orderBy('xpEarned', descending: true)
          .limit(30)
          .get();

      return snapshot.docs
          .map((doc) => LeagueParticipant.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load leaderboard: $e');
    }
  }

  /// Joins the current user to the league for the given week if not already joined.
  Future<void> joinLeague(String weekId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Ensure weekly XP is reset before reading xpThisWeek,
      // otherwise stale XP from the previous week carries over.
      await resetWeeklyXpIfNeeded();

      final participantRef = _firestore
          .collection('leagues')
          .doc(weekId)
          .collection('participants')
          .doc(user.uid);

      final doc = await participantRef.get();
      if (doc.exists) {
        // Already joined — sync xpEarned from user profile if league shows 0
        // but user has accumulated xpThisWeek (fixes stale league data).
        final data = doc.data();
        final leagueXp = data?['xpEarned'] as int? ?? 0;
        if (leagueXp == 0) {
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          final userData = userDoc.data() ?? {};
          final weeklyXp = userData['xpThisWeek'] as int? ?? 0;
          if (weeklyXp > 0) {
            await participantRef.update({'xpEarned': weeklyXp});
          }
        }
        return;
      }

      // Read user profile for display info
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final weeklyXp = userData['xpThisWeek'] as int? ?? 0;

      final participant = LeagueParticipant(
        userId: user.uid,
        displayName: userData['displayName'] ?? user.displayName ?? '',
        avatarUrl: userData['avatarUrl'],
        xpEarned: weeklyXp,
        rank: 0,
        promoted: false,
        relegated: false,
      );

      await participantRef.set(participant.toFirestore());
    } catch (e) {
      throw Exception('Failed to join league: $e');
    }
  }

  /// Returns the current user's league tier from their profile.
  Future<LeagueTier> getUserLeagueTier() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      final tierStr = data['currentLeague'] ?? 'bronze';
      return tierFromString(tierStr);
    } catch (e) {
      throw Exception('Failed to get league tier: $e');
    }
  }

  /// Returns the current user's participant entry for the given week.
  Future<LeagueParticipant?> getMyRank(String weekId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('leagues')
          .doc(weekId)
          .collection('participants')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;
      return LeagueParticipant.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get rank: $e');
    }
  }

  /// Adds XP to the current user's league participant entry for this week.
  /// Should be called whenever XP is awarded so the leaderboard stays in sync.
  /// Auto-joins the league if the user hasn't joined this week yet.
  Future<void> addXpToLeague(int xp) async {
    if (xp <= 0) return;
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final weekId = getCurrentWeekId();
      final participantRef = _firestore
          .collection('leagues')
          .doc(weekId)
          .collection('participants')
          .doc(user.uid);

      final doc = await participantRef.get();
      if (!doc.exists) {
        // Auto-join this week's league with current XP
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data() ?? {};

        final participant = LeagueParticipant(
          userId: user.uid,
          displayName:
              userData['displayName'] ?? user.displayName ?? '',
          avatarUrl: userData['avatarUrl'],
          xpEarned: xp,
          rank: 0,
          promoted: false,
          relegated: false,
        );

        await participantRef.set(participant.toFirestore());
        return;
      }

      await participantRef.update({
        'xpEarned': FieldValue.increment(xp),
      });
    } catch (_) {
      // Non-critical — don't break the main flow
    }
  }

  /// Removes XP from the current week's league entry.
  /// Used when reversing XP for a session with no page progress.
  Future<void> removeXpFromLeague(int xp) async {
    if (xp <= 0) return;
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final weekId = getCurrentWeekId();
      final participantRef = _firestore
          .collection('leagues')
          .doc(weekId)
          .collection('participants')
          .doc(user.uid);

      final doc = await participantRef.get();
      if (doc.exists) {
        await participantRef.update({
          'xpEarned': FieldValue.increment(-xp),
        });
      }
    } catch (_) {
      // Non-critical
    }
  }

  /// Top 10 get promoted.
  int getPromotionZone() => 10;

  /// Bottom 5 get relegated.
  int getRelegationZone() => 5;
}
