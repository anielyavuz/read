import 'package:cloud_firestore/cloud_firestore.dart';

enum BadgeCategory { reading, streak, focus, special }

class BadgeDefinition {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final String icon;
  final BadgeCategory category;
  final bool Function(Map<String, dynamic> stats) checkUnlock;

  const BadgeDefinition({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.icon,
    required this.category,
    required this.checkUnlock,
  });
}

class EarnedBadge {
  final String badgeId;
  final DateTime earnedAt;

  const EarnedBadge({required this.badgeId, required this.earnedAt});

  factory EarnedBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EarnedBadge(
      badgeId: doc.id,
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'earnedAt': Timestamp.fromDate(earnedAt),
    };
  }
}
