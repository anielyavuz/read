import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/challenge.dart';
import '../../../core/services/challenge_service.dart';
import '../../../core/services/inbox_service.dart';
import '../../../core/services/remote_logger_service.dart';
import 'create_challenge_state.dart';

class CreateChallengeCubit extends Cubit<CreateChallengeState> {
  final ChallengeService _challengeService;
  final InboxService _inboxService;

  CreateChallengeCubit({
    required ChallengeService challengeService,
    required InboxService inboxService,
  })  : _challengeService = challengeService,
        _inboxService = inboxService,
        super(const CreateChallengeState());

  /// Creates a new challenge with the given parameters.
  Future<void> createChallenge({
    required String title,
    required ChallengeType type,
    int? targetPages,
    int? targetMinutes,
    required DateTime startDate,
    required DateTime endDate,
    required bool isPublic,
    List<String> invitedFriendIds = const [],
  }) async {
    emit(state.copyWith(
      status: CreateChallengeStatus.creating,
      clearError: true,
    ));

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final challenge = Challenge(
        id: '',
        type: type,
        title: title,
        description: '',
        creatorId: user.uid,
        creatorName: user.displayName ?? '',
        startDate: startDate,
        endDate: endDate,
        targetPages: targetPages,
        targetMinutes: targetMinutes,
        maxParticipants: 30,
        currentParticipants: 0,
        isPublic: isPublic,
      );

      final challengeId = await _challengeService.createChallenge(challenge);
      RemoteLoggerService.challenge('Challenge created',
        challengeId: challengeId,
        challengeTitle: title,
        challengeType: type.name);

      // Send invites to selected friends for private challenges
      if (!isPublic && invitedFriendIds.isNotEmpty) {
        for (final friendId in invitedFriendIds) {
          try {
            await _inboxService.sendChallengeInvite(
              toUserId: friendId,
              challengeId: challengeId,
              challengeTitle: title,
            );
          } catch (_) {
            // Don't block creation if invite fails
          }
        }
      }

      emit(state.copyWith(status: CreateChallengeStatus.created));
    } catch (e) {
      RemoteLoggerService.error('Create challenge failed', screen: 'challenge', error: e);
      emit(state.copyWith(
        status: CreateChallengeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
