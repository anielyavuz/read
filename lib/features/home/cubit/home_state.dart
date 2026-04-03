import '../../../core/models/activity_entry.dart';
import '../../../core/models/challenge.dart';
import '../../../core/models/reader_profile.dart';
import '../../../core/models/user_profile.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final UserProfile? userProfile;
  final int pagesReadToday;
  final int pendingFriendRequests;
  final int unreadInboxCount;
  final List<ActivityEntry> activityEntries;
  final ReaderProfile? readerProfile;
  final List<Challenge> myChallenges;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.userProfile,
    this.pagesReadToday = 0,
    this.pendingFriendRequests = 0,
    this.unreadInboxCount = 0,
    this.activityEntries = const [],
    this.readerProfile,
    this.myChallenges = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    UserProfile? userProfile,
    int? pagesReadToday,
    int? pendingFriendRequests,
    int? unreadInboxCount,
    List<ActivityEntry>? activityEntries,
    ReaderProfile? readerProfile,
    List<Challenge>? myChallenges,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      pagesReadToday: pagesReadToday ?? this.pagesReadToday,
      pendingFriendRequests: pendingFriendRequests ?? this.pendingFriendRequests,
      unreadInboxCount: unreadInboxCount ?? this.unreadInboxCount,
      activityEntries: activityEntries ?? this.activityEntries,
      readerProfile: readerProfile ?? this.readerProfile,
      myChallenges: myChallenges ?? this.myChallenges,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
