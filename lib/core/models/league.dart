import 'package:cloud_firestore/cloud_firestore.dart';

enum LeagueTier { bronze, silver, gold, platinum, diamond }

LeagueTier tierFromString(String value) {
  switch (value) {
    case 'silver':
      return LeagueTier.silver;
    case 'gold':
      return LeagueTier.gold;
    case 'platinum':
      return LeagueTier.platinum;
    case 'diamond':
      return LeagueTier.diamond;
    default:
      return LeagueTier.bronze;
  }
}

String tierToString(LeagueTier tier) {
  switch (tier) {
    case LeagueTier.bronze:
      return 'bronze';
    case LeagueTier.silver:
      return 'silver';
    case LeagueTier.gold:
      return 'gold';
    case LeagueTier.platinum:
      return 'platinum';
    case LeagueTier.diamond:
      return 'diamond';
  }
}

class LeagueParticipant {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int xpEarned;
  final int rank;
  final bool promoted;
  final bool relegated;

  const LeagueParticipant({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.xpEarned = 0,
    this.rank = 0,
    this.promoted = false,
    this.relegated = false,
  });

  factory LeagueParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeagueParticipant(
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      xpEarned: data['xpEarned'] ?? 0,
      rank: data['rank'] ?? 0,
      promoted: data['promoted'] ?? false,
      relegated: data['relegated'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'xpEarned': xpEarned,
      'rank': rank,
      'promoted': promoted,
      'relegated': relegated,
    };
  }
}
