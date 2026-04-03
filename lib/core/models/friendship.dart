import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendshipStatus { pending, accepted, declined }

class Friendship {
  final String id;
  final String senderId;
  final String receiverId;
  final List<String> participants;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const Friendship({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.participants,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  factory Friendship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friendship(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      status: _statusFromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'participants': participants,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
    };
  }

  static FriendshipStatus _statusFromString(String s) {
    switch (s) {
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'declined':
        return FriendshipStatus.declined;
      default:
        return FriendshipStatus.pending;
    }
  }

  /// Generate compound doc ID from two UIDs (alphabetically sorted).
  static String docId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
