import '../../../core/services/friendship_service.dart';

enum FriendsStatus { initial, loading, loaded, error }

class FriendsState {
  final FriendsStatus status;
  final List<FriendWithProfile> friends;
  final List<FriendWithProfile> pendingRequests;
  final List<SearchResult> searchResults;
  final String searchQuery;
  final bool isSearching;
  final bool hasSearched;
  final String? errorMessage;

  const FriendsState({
    this.status = FriendsStatus.initial,
    this.friends = const [],
    this.pendingRequests = const [],
    this.searchResults = const [],
    this.searchQuery = '',
    this.isSearching = false,
    this.hasSearched = false,
    this.errorMessage,
  });

  FriendsState copyWith({
    FriendsStatus? status,
    List<FriendWithProfile>? friends,
    List<FriendWithProfile>? pendingRequests,
    List<SearchResult>? searchResults,
    String? searchQuery,
    bool? isSearching,
    bool? hasSearched,
    String? errorMessage,
  }) {
    return FriendsState(
      status: status ?? this.status,
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      hasSearched: hasSearched ?? this.hasSearched,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
