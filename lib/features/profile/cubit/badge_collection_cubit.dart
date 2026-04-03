import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/badge.dart';
import '../../../core/services/badge_service.dart';
import 'badge_collection_state.dart';

class BadgeCollectionCubit extends Cubit<BadgeCollectionState> {
  final BadgeService _badgeService;

  BadgeCollectionCubit({required BadgeService badgeService})
      : _badgeService = badgeService,
        super(const BadgeCollectionState());

  Future<void> loadBadges() async {
    emit(state.copyWith(status: BadgeCollectionStatus.loading));
    try {
      final earnedBadges = await _badgeService.getEarnedBadges();
      emit(state.copyWith(
        status: BadgeCollectionStatus.loaded,
        earnedBadges: earnedBadges,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BadgeCollectionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void filterByCategory(BadgeCategory? category) {
    emit(state.copyWith(selectedCategory: () => category));
  }
}
