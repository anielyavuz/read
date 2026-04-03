import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/badge.dart';
import '../constants/badge_definitions.dart';

class BadgeService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BadgeService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _badgesRef =>
      _firestore.collection('users').doc(_uid).collection('badges');

  /// Gets all earned badges for the current user.
  Future<List<EarnedBadge>> getEarnedBadges() async {
    if (_uid == null) return [];
    try {
      final snapshot = await _badgesRef.get();
      return snapshot.docs
          .map((doc) => EarnedBadge.fromFirestore(doc))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Checks all badge conditions against current user stats.
  /// Awards any newly unlocked badges. Returns list of NEWLY earned badge IDs.
  Future<List<String>> checkAndAwardBadges() async {
    if (_uid == null) return [];

    try {
      // Get current stats from user profile
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final userData = userDoc.data() ?? {};

      // Get focus session count
      final focusSessions = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('focusSessions')
          .where('completed', isEqualTo: true)
          .get();

      final stats = {
        'pagesRead': userData['pagesRead'] ?? 0,
        'booksRead': userData['booksRead'] ?? 0,
        'streakDays': userData['streakDays'] ?? 0,
        'focusSessionCount': focusSessions.docs.length,
        'companionLevel': userData['companionLevel'] ?? 1,
        'focusMinutesTotal': userData['focusMinutesTotal'] ?? 0,
      };

      // Get already earned badges
      final earnedSnapshot = await _badgesRef.get();
      final earnedIds = earnedSnapshot.docs.map((doc) => doc.id).toSet();

      // Check each badge
      final newlyEarned = <String>[];
      for (final badge in allBadges) {
        if (earnedIds.contains(badge.id)) continue;
        if (badge.checkUnlock(stats)) {
          await _badgesRef.doc(badge.id).set(
                EarnedBadge(
                  badgeId: badge.id,
                  earnedAt: DateTime.now(),
                ).toFirestore(),
              );
          newlyEarned.add(badge.id);
        }
      }

      return newlyEarned;
    } catch (_) {
      return [];
    }
  }

  /// Gets a badge definition by ID.
  BadgeDefinition? getBadgeDefinition(String badgeId) {
    try {
      return allBadges.firstWhere((b) => b.id == badgeId);
    } catch (_) {
      return null;
    }
  }
}
