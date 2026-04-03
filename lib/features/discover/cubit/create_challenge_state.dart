enum CreateChallengeStatus { initial, creating, created, error }

class CreateChallengeState {
  final CreateChallengeStatus status;
  final String? errorMessage;

  const CreateChallengeState({
    this.status = CreateChallengeStatus.initial,
    this.errorMessage,
  });

  CreateChallengeState copyWith({
    CreateChallengeStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateChallengeState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
