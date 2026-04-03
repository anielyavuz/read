import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';

class ChallengeService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChallengeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Returns active public challenges ordered by start date.
  Future<List<Challenge>> getActiveChallenges() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('challenges')
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('endDate')
          .get();

      return snapshot.docs
          .map((doc) => Challenge.fromFirestore(doc))
          .where((c) => c.isPublic)
          .toList();
    } catch (e) {
      throw Exception('Failed to load challenges: $e');
    }
  }

  /// Returns a single challenge by ID.
  Future<Challenge> getChallenge(String id) async {
    try {
      final doc = await _firestore.collection('challenges').doc(id).get();
      if (!doc.exists) throw Exception('Challenge not found');
      return Challenge.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to load challenge: $e');
    }
  }

  /// Returns participants for a challenge, ordered by progress descending.
  /// Ranks are computed client-side based on progress.
  Future<List<ChallengeParticipant>> getChallengeParticipants(
      String id) async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .doc(id)
          .collection('participants')
          .orderBy('progress', descending: true)
          .get();

      final participants = <ChallengeParticipant>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        final p = ChallengeParticipant.fromFirestore(snapshot.docs[i]);
        // Assign rank based on progress order (1-indexed)
        participants.add(ChallengeParticipant(
          userId: p.userId,
          displayName: p.displayName,
          avatarUrl: p.avatarUrl,
          progress: p.progress,
          rank: i + 1,
          joinedAt: p.joinedAt,
          lastUpdateAt: p.lastUpdateAt,
        ));
      }
      return participants;
    } catch (e) {
      throw Exception('Failed to load participants: $e');
    }
  }

  /// Joins the current user to a challenge using a Firestore transaction
  /// to prevent race conditions on participant count.
  Future<void> joinChallenge(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Read user profile for tier check
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final tier = userData['subscriptionTier'] ?? 'free';

      // Check tier limits
      final activeCount = await getMyActiveChallengeCount();
      if (tier == 'free' && activeCount >= 1) {
        throw Exception('Free users can join max 1 active challenge');
      }
      if (tier == 'reader' && activeCount >= 3) {
        throw Exception('Reader users can join max 3 active challenges');
      }

      final challengeRef = _firestore.collection('challenges').doc(id);
      final participantRef = challengeRef.collection('participants').doc(user.uid);

      // Use transaction for atomic check-and-join
      await _firestore.runTransaction((transaction) async {
        final challengeSnap = await transaction.get(challengeRef);
        if (!challengeSnap.exists) throw Exception('Challenge not found');

        final data = challengeSnap.data()!;
        final currentParticipants = data['currentParticipants'] ?? 0;
        final maxParticipants = data['maxParticipants'] ?? 30;

        if (currentParticipants >= maxParticipants) {
          throw Exception('Challenge is full');
        }

        final existingParticipant = await transaction.get(participantRef);
        if (existingParticipant.exists) return; // Already participating

        final now = DateTime.now();
        final participant = ChallengeParticipant(
          userId: user.uid,
          displayName: userData['displayName'] ?? user.displayName ?? '',
          avatarUrl: userData['avatarUrl'],
          progress: 0,
          rank: 0, // Rank is computed on read, not stored
          joinedAt: now,
          lastUpdateAt: now,
        );

        transaction.set(participantRef, participant.toFirestore());
        transaction.update(challengeRef, {
          'currentParticipants': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Exception('Failed to join challenge: $e');
    }
  }

  /// Removes the current user from a challenge.
  Future<void> leaveChallenge(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final challengeRef = _firestore.collection('challenges').doc(id);
      final participantRef = challengeRef.collection('participants').doc(user.uid);

      // Use transaction for atomic delete + decrement
      await _firestore.runTransaction((transaction) async {
        final participantSnap = await transaction.get(participantRef);
        if (!participantSnap.exists) return; // Not participating

        transaction.delete(participantRef);
        transaction.update(challengeRef, {
          'currentParticipants': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      throw Exception('Failed to leave challenge: $e');
    }
  }

  /// Creates a new challenge. All users can create challenges.
  /// The creator is automatically joined as the first participant.
  Future<String> createChallenge(Challenge challenge) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final docRef = await _firestore
          .collection('challenges')
          .add(challenge.toFirestore());

      // Auto-join creator as first participant
      final now = DateTime.now();
      final participant = ChallengeParticipant(
        userId: user.uid,
        displayName: userData['displayName'] ?? user.displayName ?? '',
        avatarUrl: userData['avatarUrl'],
        progress: 0,
        rank: 1,
        joinedAt: now,
        lastUpdateAt: now,
      );

      await _firestore
          .collection('challenges')
          .doc(docRef.id)
          .collection('participants')
          .doc(user.uid)
          .set(participant.toFirestore());

      // Update participant count
      await docRef.update({'currentParticipants': 1});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create challenge: $e');
    }
  }

  /// Returns the number of active challenges the current user is participating in.
  /// Uses parallel lookups instead of sequential N+1 queries.
  Future<int> getMyActiveChallengeCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final now = DateTime.now();
      final challengesSnapshot = await _firestore
          .collection('challenges')
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .get();

      // Parallel participant lookups instead of sequential
      final futures = challengesSnapshot.docs.map((challengeDoc) {
        return _firestore
            .collection('challenges')
            .doc(challengeDoc.id)
            .collection('participants')
            .doc(user.uid)
            .get();
      });

      final results = await Future.wait(futures);
      return results.where((doc) => doc.exists).length;
    } catch (e) {
      throw Exception('Failed to count active challenges: $e');
    }
  }

  /// Returns challenges the current user is actively participating in.
  /// Uses parallel lookups instead of sequential N+1 queries.
  Future<List<Challenge>> getMyChallenges() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final challengesSnapshot = await _firestore
          .collection('challenges')
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('endDate')
          .get();

      // Parallel participant lookups
      final docs = challengesSnapshot.docs;
      final futures = docs.map((doc) {
        return _firestore
            .collection('challenges')
            .doc(doc.id)
            .collection('participants')
            .doc(user.uid)
            .get();
      });

      final results = await Future.wait(futures);
      final myChallenges = <Challenge>[];
      for (int i = 0; i < docs.length; i++) {
        if (results[i].exists) {
          myChallenges.add(Challenge.fromFirestore(docs[i]));
        }
      }
      return myChallenges;
    } catch (e) {
      throw Exception('Failed to load my challenges: $e');
    }
  }

  /// Creates a challenge from a template and auto-joins the creator.
  Future<String> createFromTemplate({
    required String title,
    required String description,
    required ChallengeType type,
    int? targetPages,
    int? targetBooks,
    int? targetMinutes,
    required int durationDays,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final now = DateTime.now();
      final challenge = Challenge(
        id: '',
        type: type,
        title: title,
        description: description,
        creatorId: user.uid,
        creatorName: userData['displayName'] ?? user.displayName ?? '',
        startDate: now,
        endDate: now.add(Duration(days: durationDays)),
        targetPages: targetPages,
        targetBooks: targetBooks,
        targetMinutes: targetMinutes,
        maxParticipants: 30,
        currentParticipants: 1,
        isPublic: true,
      );

      final docRef =
          await _firestore.collection('challenges').add(challenge.toFirestore());

      // Auto-join creator
      final participant = ChallengeParticipant(
        userId: user.uid,
        displayName: userData['displayName'] ?? user.displayName ?? '',
        avatarUrl: userData['avatarUrl'],
        progress: 0,
        rank: 1,
        joinedAt: now,
        lastUpdateAt: now,
      );

      await _firestore
          .collection('challenges')
          .doc(docRef.id)
          .collection('participants')
          .doc(user.uid)
          .set(participant.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create challenge: $e');
    }
  }

  /// Checks if the current user is participating in a challenge.
  Future<bool> isParticipating(String challengeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .collection('participants')
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check participation: $e');
    }
  }

  /// Updates the current user's progress in all active challenges they're in.
  ///
  /// [pagesRead] — increment for pages-type challenges.
  /// [minutesRead] — increment for sprint/minutes-type challenges.
  /// [booksFinished] — increment for genre-type challenges.
  ///
  /// Returns list of challenge IDs where the user just hit the target.
  Future<List<String>> updateMyProgress({
    int pagesRead = 0,
    int minutesRead = 0,
    int booksFinished = 0,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final myChallenges = await getMyChallenges();
      final completedChallengeIds = <String>[];

      for (final challenge in myChallenges) {
        int increment = 0;
        int? target;

        switch (challenge.type) {
          case ChallengeType.pages:
          case ChallengeType.readAlong:
            increment = pagesRead;
            target = challenge.targetPages;
            break;
          case ChallengeType.sprint:
            increment = minutesRead;
            target = challenge.targetMinutes;
            break;
          case ChallengeType.genre:
            increment = booksFinished;
            target = challenge.targetBooks;
            break;
        }

        if (increment <= 0) continue;

        final participantRef = _firestore
            .collection('challenges')
            .doc(challenge.id)
            .collection('participants')
            .doc(user.uid);

        final participantDoc = await participantRef.get();
        if (!participantDoc.exists) continue;

        final currentProgress =
            (participantDoc.data()?['progress'] as int?) ?? 0;
        final newProgress = currentProgress + increment;

        await participantRef.update({
          'progress': newProgress,
          'lastUpdateAt': Timestamp.fromDate(DateTime.now()),
        });

        // Check if just hit target
        if (target != null &&
            currentProgress < target &&
            newProgress >= target) {
          completedChallengeIds.add(challenge.id);
        }
      }

      return completedChallengeIds;
    } catch (e) {
      // Log error but don't break the main reading flow
      // ignore: avoid_print
      print('Challenge progress update failed: $e');
      return [];
    }
  }
}
