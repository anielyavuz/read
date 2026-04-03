import 'package:cloud_firestore/cloud_firestore.dart';

enum InboxNotificationType { challengeInvite, pushNotification }

class InboxNotification {
  final String id;
  final InboxNotificationType type;

  // Challenge invite fields (nullable — only used for challengeInvite)
  final String? challengeId;
  final String? challengeTitle;
  final String? fromUserId;
  final String? fromUserName;

  // Push notification fields (nullable — only used for pushNotification)
  final String? title;
  final String? body;

  final DateTime createdAt;
  final bool read;
  final String? actionTaken; // "accepted", "rejected", or null

  const InboxNotification({
    required this.id,
    required this.type,
    this.challengeId,
    this.challengeTitle,
    this.fromUserId,
    this.fromUserName,
    this.title,
    this.body,
    required this.createdAt,
    this.read = false,
    this.actionTaken,
  });

  factory InboxNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InboxNotification(
      id: doc.id,
      type: _typeFromString(data['type'] ?? 'challengeInvite'),
      challengeId: data['challengeId'] as String?,
      challengeTitle: data['challengeTitle'] as String?,
      fromUserId: data['fromUserId'] as String?,
      fromUserName: data['fromUserName'] as String?,
      title: data['title'] as String?,
      body: data['body'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      actionTaken: data['actionTaken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      if (challengeId != null) 'challengeId': challengeId,
      if (challengeTitle != null) 'challengeTitle': challengeTitle,
      if (fromUserId != null) 'fromUserId': fromUserId,
      if (fromUserName != null) 'fromUserName': fromUserName,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      if (actionTaken != null) 'actionTaken': actionTaken,
    };
  }

  InboxNotification copyWith({
    String? id,
    InboxNotificationType? type,
    String? challengeId,
    String? challengeTitle,
    String? fromUserId,
    String? fromUserName,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? read,
    String? actionTaken,
  }) {
    return InboxNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      actionTaken: actionTaken ?? this.actionTaken,
    );
  }

  static InboxNotificationType _typeFromString(String s) {
    switch (s) {
      case 'challengeInvite':
        return InboxNotificationType.challengeInvite;
      case 'pushNotification':
        return InboxNotificationType.pushNotification;
      default:
        return InboxNotificationType.pushNotification;
    }
  }
}
