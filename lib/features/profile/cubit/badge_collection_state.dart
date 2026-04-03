import '../../../core/models/badge.dart';

enum BadgeCollectionStatus { initial, loading, loaded, error }

class BadgeCollectionState {
  final BadgeCollectionStatus status;
  final List<EarnedBadge> earnedBadges;
  final BadgeCategory? selectedCategory;
  final String? errorMessage;

  const BadgeCollectionState({
    this.status = BadgeCollectionStatus.initial,
    this.earnedBadges = const [],
    this.selectedCategory,
    this.errorMessage,
  });

  BadgeCollectionState copyWith({
    BadgeCollectionStatus? status,
    List<EarnedBadge>? earnedBadges,
    BadgeCategory? Function()? selectedCategory,
    String? errorMessage,
  }) {
    return BadgeCollectionState(
      status: status ?? this.status,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
