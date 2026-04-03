import '../../../core/models/challenge.dart';

enum ChallengeDetailStatus { initial, loading, loaded, joining, leaving, error }

class ChallengeDetailState {
  final ChallengeDetailStatus status;
  final Challenge? challenge;
  final List<ChallengeParticipant> participants;
  final bool isParticipating;
  final int myProgress;
  final String? errorMessage;

  const ChallengeDetailState({
    this.status = ChallengeDetailStatus.initial,
    this.challenge,
    this.participants = const [],
    this.isParticipating = false,
    this.myProgress = 0,
    this.errorMessage,
  });

  ChallengeDetailState copyWith({
    ChallengeDetailStatus? status,
    Challenge? challenge,
    List<ChallengeParticipant>? participants,
    bool? isParticipating,
    int? myProgress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChallengeDetailState(
      status: status ?? this.status,
      challenge: challenge ?? this.challenge,
      participants: participants ?? this.participants,
      isParticipating: isParticipating ?? this.isParticipating,
      myProgress: myProgress ?? this.myProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
