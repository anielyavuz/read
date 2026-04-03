import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/league.dart';
import '../../../core/services/friendship_service.dart';
import '../../../core/services/league_service.dart';
import 'league_state.dart';

class LeagueCubit extends Cubit<LeagueState> {
  final LeagueService _leagueService;
  final FriendshipService _friendshipService;

  LeagueCubit({
    required LeagueService leagueService,
    required FriendshipService friendshipService,
  })  : _leagueService = leagueService,
        _friendshipService = friendshipService,
        super(const LeagueState());

  /// Loads the league: gets tier, joins if needed, loads leaderboard, finds my entry.
  Future<void> loadLeague() async {
    emit(state.copyWith(status: LeagueStatus.loading, clearError: true));

    try {
      final tier = await _leagueService.getUserLeagueTier();
      final weekId = _leagueService.getCurrentWeekId();

      // Auto-join if not already in this week's league
      await _leagueService.joinLeague(weekId);

      final leaderboard = await _leagueService.getLeaderboard(weekId);
      var myEntry = await _leagueService.getMyRank(weekId);

      // Calculate actual rank from leaderboard position (sorted by XP desc)
      myEntry = _resolveRank(myEntry, leaderboard);

      emit(state.copyWith(
        status: LeagueStatus.loaded,
        currentTier: tier,
        leaderboard: leaderboard,
        myEntry: myEntry,
      ));

      // Load friends' reading data in background (non-blocking)
      _loadFriendsReading();
    } catch (e) {
      emit(state.copyWith(
        status: LeagueStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Loads friends' currently reading books (fire-and-forget).
  Future<void> _loadFriendsReading() async {
    try {
      final friends = await _friendshipService.getAcceptedFriends();
      // Only include friends who are actually reading something
      final reading =
          friends.where((f) => f.currentlyReading.isNotEmpty).toList();
      emit(state.copyWith(friendsReading: reading));
    } catch (_) {
      // Non-critical — don't show error for this
    }
  }

  /// Refreshes just the leaderboard and my entry.
  Future<void> refreshLeaderboard() async {
    try {
      final weekId = _leagueService.getCurrentWeekId();
      final leaderboard = await _leagueService.getLeaderboard(weekId);
      var myEntry = await _leagueService.getMyRank(weekId);

      // Calculate actual rank from leaderboard position (sorted by XP desc)
      myEntry = _resolveRank(myEntry, leaderboard);

      emit(state.copyWith(
        leaderboard: leaderboard,
        myEntry: myEntry,
      ));

      // Also refresh friends reading
      _loadFriendsReading();
    } catch (e) {
      emit(state.copyWith(
        status: LeagueStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Calculates the user's actual rank from their position in the sorted leaderboard.
  LeagueParticipant? _resolveRank(
    LeagueParticipant? entry,
    List<LeagueParticipant> leaderboard,
  ) {
    if (entry == null) return null;
    final index = leaderboard.indexWhere((p) => p.userId == entry.userId);
    if (index < 0) return entry;
    return LeagueParticipant(
      userId: entry.userId,
      displayName: entry.displayName,
      avatarUrl: entry.avatarUrl,
      xpEarned: entry.xpEarned,
      rank: index + 1,
      promoted: entry.promoted,
      relegated: entry.relegated,
    );
  }
}
