import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inbox_notification.dart';

class InboxService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  InboxService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  /// Send a challenge invite notification to a user.
  /// Prevents duplicate invites for the same challenge from the same sender
  /// (unless the previous one was rejected).
  Future<void> sendChallengeInvite({
    required String toUserId,
    required String challengeId,
    required String challengeTitle,
  }) async {
    if (_uid == null) return;

    // Check for existing non-rejected invite from same user for same challenge
    final existing = await _notificationsRef(toUserId)
        .where('type', isEqualTo: 'challengeInvite')
        .where('challengeId', isEqualTo: challengeId)
        .where('fromUserId', isEqualTo: _uid)
        .get();

    final hasPendingOrAccepted = existing.docs.any((doc) {
      final action = doc.data()['actionTaken'] as String?;
      return action != 'rejected';
    });

    if (hasPendingOrAccepted) return;

    // Get current user's display name
    final userDoc =
        await _firestore.collection('users').doc(_uid).get();
    final fromUserName =
        (userDoc.data()?['displayName'] as String?) ?? '';

    final notification = InboxNotification(
      id: '',
      type: InboxNotificationType.challengeInvite,
      challengeId: challengeId,
      challengeTitle: challengeTitle,
      fromUserId: _uid!,
      fromUserName: fromUserName,
      createdAt: DateTime.now(),
    );

    await _notificationsRef(toUserId).add(notification.toFirestore());
  }

  /// Save an incoming push notification to Firestore.
  Future<void> savePushNotification({
    required String title,
    required String body,
  }) async {
    if (_uid == null) return;

    final notification = InboxNotification(
      id: '',
      type: InboxNotificationType.pushNotification,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );

    await _notificationsRef(_uid!).add(notification.toFirestore());
  }

  /// Get all notifications for the current user, ordered by newest first.
  Future<List<InboxNotification>> getNotifications() async {
    if (_uid == null) return [];

    final snapshot = await _notificationsRef(_uid!)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => InboxNotification.fromFirestore(doc))
        .toList();
  }

  /// Get the count of unread notifications for the current user.
  Future<int> getUnreadCount() async {
    if (_uid == null) return 0;

    final snapshot = await _notificationsRef(_uid!)
        .where('read', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  /// Accept a challenge invite: sets actionTaken to 'accepted' and marks as read.
  Future<void> acceptInvite(String notificationId) async {
    if (_uid == null) return;

    await _notificationsRef(_uid!).doc(notificationId).update({
      'actionTaken': 'accepted',
      'read': true,
    });
  }

  /// Reject a challenge invite: sets actionTaken to 'rejected' and marks as read.
  Future<void> rejectInvite(String notificationId) async {
    if (_uid == null) return;

    await _notificationsRef(_uid!).doc(notificationId).update({
      'actionTaken': 'rejected',
      'read': true,
    });
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    if (_uid == null) return;

    await _notificationsRef(_uid!).doc(notificationId).update({
      'read': true,
    });
  }

  /// Delete a notification.
  Future<void> deleteNotification(String notificationId) async {
    if (_uid == null) return;

    await _notificationsRef(_uid!).doc(notificationId).delete();
  }
}
