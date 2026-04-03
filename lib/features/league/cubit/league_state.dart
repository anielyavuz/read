import '../../../core/models/league.dart';
import '../../../core/services/friendship_service.dart';

enum LeagueStatus { initial, loading, loaded, error }

class LeagueState {
  final LeagueStatus status;
  final LeagueTier currentTier;
  final List<LeagueParticipant> leaderboard;
  final LeagueParticipant? myEntry;
  final List<FriendWithProfile> friendsReading;
  final String? errorMessage;

  const LeagueState({
    this.status = LeagueStatus.initial,
    this.currentTier = LeagueTier.bronze,
    this.leaderboard = const [],
    this.myEntry,
    this.friendsReading = const [],
    this.errorMessage,
  });

  LeagueState copyWith({
    LeagueStatus? status,
    LeagueTier? currentTier,
    List<LeagueParticipant>? leaderboard,
    LeagueParticipant? myEntry,
    bool clearMyEntry = false,
    List<FriendWithProfile>? friendsReading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LeagueState(
      status: status ?? this.status,
      currentTier: currentTier ?? this.currentTier,
      leaderboard: leaderboard ?? this.leaderboard,
      myEntry: clearMyEntry ? null : (myEntry ?? this.myEntry),
      friendsReading: friendsReading ?? this.friendsReading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
