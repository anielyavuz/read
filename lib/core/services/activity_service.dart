import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_entry.dart';

/// Service for logging and retrieving reading journey activity entries.
///
/// Merges explicit activity log entries with historical data from
/// focusSessions and badges subcollections so the journey path
/// is populated even before the logging feature was added.
class ActivityService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ActivityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _entriesRef =>
      _userDoc.collection('activityLog');

  /// Logs a new activity entry.
  Future<void> log(ActivityEntry entry) async {
    if (_uid == null) return;
    await _entriesRef.add(entry.toFirestore());
  }

  /// Deletes an activity entry from the activityLog subcollection.
  ///
  /// For badge entries, also deletes the corresponding document from the
  /// `badges` subcollection so it won't reappear via the fallback merge
  /// in [getRecentEntries].
  Future<void> deleteEntry(String entryId) async {
    if (_uid == null) return;

    // Read the entry first to check if it's a badge.
    try {
      final doc = await _entriesRef.doc(entryId).get();
      if (doc.exists) {
        final data = doc.data();
        final type = data?['type'];
        final badgeId = data?['badgeId'] as String?;

        // Delete the activityLog entry.
        await _entriesRef.doc(entryId).delete();

        // If it's a badge entry, also remove the badge record so it
        // doesn't get re-surfaced by _fetchEarnedBadges().
        if (type == ActivityType.badgeEarned.name && badgeId != null) {
          await _userDoc.collection('badges').doc(badgeId).delete();
        }
      } else {
        // Doc doesn't exist, nothing to delete.
        await _entriesRef.doc(entryId).delete();
      }
    } catch (_) {
      // Fallback: at minimum try to delete the activityLog entry.
      await _entriesRef.doc(entryId).delete();
    }
  }

  /// Fetches recent activities by merging:
  /// 1. Explicit activityLog entries (new system)
  /// 2. Completed focusSessions (historical)
  /// 3. Earned badges (historical)
  ///
  /// De-duplicates by checking timestamps within a 2-second window.
  Future<List<ActivityEntry>> getRecentEntries({int limit = 30}) async {
    if (_uid == null) return [];

    final results = await Future.wait([
      _fetchActivityLogEntries(limit),
      _fetchFocusSessions(limit),
      _fetchEarnedBadges(),
    ]);

    final logEntries = results[0];
    final sessionEntries = results[1];
    final badgeEntries = results[2];

    // Merge all sources
    final all = <ActivityEntry>[...logEntries];

    // Add historical sessions that aren't already in activityLog
    for (final session in sessionEntries) {
      if (!_hasDuplicate(all, session)) {
        all.add(session);
      }
    }

    // Add historical badges ONLY if no badge entries exist in activityLog.
    // Once the logging system starts recording badges, the badges subcollection
    // is no longer used as a source — this prevents deleted entries from
    // reappearing via the fallback source.
    final hasBadgeInLog =
        logEntries.any((e) => e.type == ActivityType.badgeEarned);
    if (!hasBadgeInLog) {
      for (final badge in badgeEntries) {
        if (!_hasDuplicate(all, badge)) {
          all.add(badge);
        }
      }
    }

    // Sort by timestamp descending and limit
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.length > limit ? all.sublist(0, limit) : all;
  }

  /// Check if an entry with the same type and close timestamp already exists.
  bool _hasDuplicate(List<ActivityEntry> entries, ActivityEntry candidate) {
    for (final e in entries) {
      if (e.type != candidate.type) continue;
      final diff = e.timestamp.difference(candidate.timestamp).abs();
      if (diff.inSeconds < 5) return true;
    }
    return false;
  }

  Future<List<ActivityEntry>> _fetchActivityLogEntries(int limit) async {
    try {
      final snap = await _entriesRef
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => ActivityEntry.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ActivityEntry>> _fetchFocusSessions(int limit) async {
    try {
      final snap = await _userDoc
          .collection('focusSessions')
          .where('completed', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        final ts = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return ActivityEntry(
          id: doc.id,
          type: ActivityType.focusSession,
          timestamp: ts,
          xpEarned: data['xpEarned'] ?? 0,
          durationMinutes: data['durationMinutes'] ?? 0,
          bookTitle: data['bookTitle'],
          pagesRead: data['pagesRead'] ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ActivityEntry>> _fetchEarnedBadges() async {
    try {
      final snap = await _userDoc.collection('badges').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        final ts = (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return ActivityEntry(
          id: doc.id,
          type: ActivityType.badgeEarned,
          timestamp: ts,
          badgeId: doc.id,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
