import '../../../core/models/challenge.dart';

enum DiscoverStatus { initial, loading, loaded, error }

class DiscoverState {
  final DiscoverStatus status;
  final List<Challenge> communityChallenges;
  final List<Challenge> myChallenges;
  final String? errorMessage;

  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.communityChallenges = const [],
    this.myChallenges = const [],
    this.errorMessage,
  });

  /// Backward compat alias.
  List<Challenge> get activeChallenges => communityChallenges;

  DiscoverState copyWith({
    DiscoverStatus? status,
    List<Challenge>? communityChallenges,
    List<Challenge>? myChallenges,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      communityChallenges: communityChallenges ?? this.communityChallenges,
      myChallenges: myChallenges ?? this.myChallenges,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
