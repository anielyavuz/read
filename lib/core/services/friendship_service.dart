import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friendship.dart';
import '../models/user_profile.dart';

class FriendshipService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FriendshipService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _friendships =>
      _firestore.collection('friendships');

  /// Search users by display name prefix (case-insensitive).
  /// Returns users with their friendship status relative to current user.
  Future<List<SearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty || _uid == null) return [];

    final lower = query.trim().toLowerCase();
    final result = await _firestore
        .collection('users')
        .where('displayNameLower', isGreaterThanOrEqualTo: lower)
        .where('displayNameLower', isLessThanOrEqualTo: '$lower\uf8ff')
        .limit(20)
        .get();

    final users = result.docs
        .where((doc) => doc.id != _uid)
        .map((doc) => UserProfile.fromFirestore(doc))
        .toList();

    final results = <SearchResult>[];
    for (final user in users) {
      final friendship = await getFriendshipWith(user.uid);
      results.add(SearchResult(profile: user, friendship: friendship));
    }
    return results;
  }

  /// Send a friend request. If reverse pending request exists, auto-accept.
  Future<void> sendRequest(String receiverId) async {
    if (_uid == null) return;

    final docId = Friendship.docId(_uid!, receiverId);
    final docRef = _friendships.doc(docId);
    final existing = await docRef.get();

    if (existing.exists) {
      final data = existing.data()!;
      final status = data['status'] as String?;

      // If there's a pending request FROM the other user, auto-accept
      if (status == 'pending' && data['senderId'] == receiverId) {
        await docRef.update({
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Already exists (accepted or we already sent) — do nothing
      return;
    }

    final friendship = Friendship(
      id: docId,
      senderId: _uid!,
      receiverId: receiverId,
      participants: [_uid!, receiverId],
      status: FriendshipStatus.pending,
      createdAt: DateTime.now(),
    );

    await docRef.set(friendship.toFirestore());
  }

  /// Accept a friend request.
  Future<void> acceptRequest(String friendshipId) async {
    await _friendships.doc(friendshipId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Decline a friend request.
  Future<void> declineRequest(String friendshipId) async {
    await _friendships.doc(friendshipId).delete();
  }

  /// Remove a friend.
  Future<void> removeFriend(String friendshipId) async {
    await _friendships.doc(friendshipId).delete();
  }

  /// Get accepted friends list.
  Future<List<FriendWithProfile>> getAcceptedFriends() async {
    if (_uid == null) return [];

    final snapshot = await _friendships
        .where('participants', arrayContains: _uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final friends = <FriendWithProfile>[];
    for (final doc in snapshot.docs) {
      final friendship = Friendship.fromFirestore(doc);
      final friendUid = friendship.senderId == _uid
          ? friendship.receiverId
          : friendship.senderId;

      final userDoc = await _firestore.collection('users').doc(friendUid).get();
      if (userDoc.exists) {
        // Fetch friend's currently reading books
        final readingBooks = await _fetchReadingBooks(friendUid);
        friends.add(FriendWithProfile(
          friendship: friendship,
          profile: UserProfile.fromFirestore(userDoc),
          currentlyReading: readingBooks,
        ));
      }
    }

    return friends;
  }

  /// Fetch up to 3 currently reading books for a given user.
  Future<List<FriendReadingBook>> _fetchReadingBooks(String uid) async {
    try {
      final snap = await _firestore
          .collection('userBooks')
          .doc(uid)
          .collection('library')
          .where('status', isEqualTo: 'reading')
          .limit(3)
          .get();

      return snap.docs.map((doc) {
        final d = doc.data();
        return FriendReadingBook(
          title: d['title'] ?? '',
          authors: List<String>.from(d['authors'] ?? []),
          coverUrl: d['coverUrl'] as String?,
          currentPage: d['currentPage'] ?? 0,
          totalPages: d['totalPages'] ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get pending friend requests received by current user.
  Future<List<FriendWithProfile>> getPendingRequests() async {
    if (_uid == null) return [];

    final snapshot = await _friendships
        .where('receiverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .get();

    final requests = <FriendWithProfile>[];
    for (final doc in snapshot.docs) {
      final friendship = Friendship.fromFirestore(doc);
      final userDoc = await _firestore
          .collection('users')
          .doc(friendship.senderId)
          .get();
      if (userDoc.exists) {
        requests.add(FriendWithProfile(
          friendship: friendship,
          profile: UserProfile.fromFirestore(userDoc),
        ));
      }
    }

    return requests;
  }

  /// Get count of pending friend requests.
  Future<int> getPendingRequestCount() async {
    if (_uid == null) return 0;

    final snapshot = await _friendships
        .where('receiverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }

  /// Get existing friendship status between current user and another user.
  Future<Friendship?> getFriendshipWith(String otherUid) async {
    if (_uid == null) return null;

    final docId = Friendship.docId(_uid!, otherUid);
    final doc = await _friendships.doc(docId).get();

    if (!doc.exists) return null;
    return Friendship.fromFirestore(doc);
  }
}

class FriendReadingBook {
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final int currentPage;
  final int totalPages;

  const FriendReadingBook({
    required this.title,
    required this.authors,
    this.coverUrl,
    this.currentPage = 0,
    this.totalPages = 0,
  });
}

class FriendWithProfile {
  final Friendship friendship;
  final UserProfile profile;
  final List<FriendReadingBook> currentlyReading;

  const FriendWithProfile({
    required this.friendship,
    required this.profile,
    this.currentlyReading = const [],
  });
}

class SearchResult {
  final UserProfile profile;
  final Friendship? friendship;

  const SearchResult({required this.profile, this.friendship});
}
