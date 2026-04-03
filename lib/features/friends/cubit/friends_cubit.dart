import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/friendship_service.dart';
import '../../../core/services/remote_logger_service.dart';
import 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  final FriendshipService _friendshipService;

  FriendsCubit({required FriendshipService friendshipService})
      : _friendshipService = friendshipService,
        super(const FriendsState());

  Future<void> loadFriends() async {
    emit(state.copyWith(status: FriendsStatus.loading));
    try {
      final friends = await _friendshipService.getAcceptedFriends();
      final pending = await _friendshipService.getPendingRequests();
      emit(state.copyWith(
        status: FriendsStatus.loaded,
        friends: friends,
        pendingRequests: pending,
      ));
    } catch (e) {
      RemoteLoggerService.error('Load friends failed', screen: 'friends', error: e);
      emit(state.copyWith(
        status: FriendsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    if (query.trim().isEmpty) {
      emit(state.copyWith(searchResults: [], isSearching: false));
    }
  }

  Future<void> performSearch() async {
    final query = state.searchQuery.trim();
    if (query.isEmpty) return;

    emit(state.copyWith(isSearching: true, hasSearched: true));
    try {
      final results = await _friendshipService.searchUsers(query);
      if (!isClosed) {
        emit(state.copyWith(searchResults: results, isSearching: false));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(searchResults: [], isSearching: false));
      }
    }
  }

  Future<void> sendRequest(String receiverId) async {
    try {
      await _friendshipService.sendRequest(receiverId);
      RemoteLoggerService.social('Friend request sent',
        details: {'receiver_id': receiverId});
      await performSearch();
    } catch (_) {}
  }

  Future<void> acceptRequest(String friendshipId) async {
    try {
      await _friendshipService.acceptRequest(friendshipId);
      RemoteLoggerService.social('Friend request accepted');
      await loadFriends();
    } catch (_) {}
  }

  Future<void> declineRequest(String friendshipId) async {
    try {
      await _friendshipService.declineRequest(friendshipId);
      await loadFriends();
    } catch (_) {}
  }

  Future<void> removeFriend(String friendshipId) async {
    try {
      await _friendshipService.removeFriend(friendshipId);
      RemoteLoggerService.social('Friend removed');
      await loadFriends();
    } catch (_) {}
  }

  void clearSearch() {
    emit(state.copyWith(
        searchQuery: '',
        searchResults: [],
        isSearching: false,
        hasSearched: false));
  }
}
