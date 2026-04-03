import '../../../core/models/badge.dart';
import '../../../core/models/user_profile.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState {
  final ProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;
  final List<EarnedBadge> earnedBadges;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.earnedBadges = const [],
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? errorMessage,
    List<EarnedBadge>? earnedBadges,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      earnedBadges: earnedBadges ?? this.earnedBadges,
    );
  }
}
