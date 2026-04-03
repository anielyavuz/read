import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/challenge.dart';
import '../../../core/services/challenge_service.dart';
import 'discover_state.dart';

class DiscoverCubit extends Cubit<DiscoverState> {
  final ChallengeService _challengeService;

  DiscoverCubit({
    required ChallengeService challengeService,
  })  : _challengeService = challengeService,
        super(const DiscoverState());

  /// Loads both community challenges and user's active challenges.
  Future<void> loadChallenges() async {
    // Only show loading spinner on the first load
    final isFirstLoad = state.status == DiscoverStatus.initial;
    if (isFirstLoad) {
      emit(state.copyWith(status: DiscoverStatus.loading, clearError: true));
    }

    try {
      final results = await Future.wait([
        _challengeService.getActiveChallenges(),
        _challengeService.getMyChallenges(),
      ]);

      emit(state.copyWith(
        status: DiscoverStatus.loaded,
        communityChallenges: results[0],
        myChallenges: results[1],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DiscoverStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Refreshes all challenge data.
  Future<void> refreshChallenges() async {
    try {
      final results = await Future.wait([
        _challengeService.getActiveChallenges(),
        _challengeService.getMyChallenges(),
      ]);

      emit(state.copyWith(
        status: DiscoverStatus.loaded,
        communityChallenges: results[0],
        myChallenges: results[1],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DiscoverStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Creates a challenge from a template and refreshes the list.
  Future<void> createFromTemplate({
    required String title,
    required String description,
    required ChallengeType type,
    int? targetPages,
    int? targetBooks,
    int? targetMinutes,
    required int durationDays,
  }) async {
    try {
      await _challengeService.createFromTemplate(
        title: title,
        description: description,
        type: type,
        targetPages: targetPages,
        targetBooks: targetBooks,
        targetMinutes: targetMinutes,
        durationDays: durationDays,
      );
      await refreshChallenges();
    } catch (e) {
      emit(state.copyWith(
        status: DiscoverStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
