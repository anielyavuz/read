import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/badge_definitions.dart';
import '../../../core/models/badge.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/badge_collection_cubit.dart';
import '../cubit/badge_collection_state.dart';
import '../widgets/badge_card.dart';
import '../widgets/badge_detail_sheet.dart';

class BadgeCollectionScreen extends StatelessWidget {
  const BadgeCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BadgeCollectionCubit(
        badgeService: getIt<BadgeService>(),
      )..loadBadges(),
      child: const _BadgeCollectionView(),
    );
  }
}

class _BadgeCollectionView extends StatelessWidget {
  const _BadgeCollectionView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          l10n.badges,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<BadgeCollectionCubit, BadgeCollectionState>(
        builder: (context, state) {
          if (state.status == BadgeCollectionStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == BadgeCollectionStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage ?? l10n.somethingWentWrong,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<BadgeCollectionCubit>().loadBadges(),
                    child: Text(
                      l10n.retry,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final earnedIds = state.earnedBadges
              .map((e) => e.badgeId)
              .toSet();
          final earnedCount = earnedIds.length;
          final totalCount = allBadges.length;

          // Filter badges by selected category
          final filteredBadges = state.selectedCategory != null
              ? allBadges
                  .where((b) => b.category == state.selectedCategory)
                  .toList()
              : allBadges;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress text
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    AnimatedEmoji(AnimatedEmojis.goldMedal, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      l10n.badgesProgress(earnedCount, totalCount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Category filter chips
              _CategoryFilterRow(
                selectedCategory: state.selectedCategory,
                onSelected: (category) =>
                    context.read<BadgeCollectionCubit>().filterByCategory(
                          category,
                        ),
              ),
              const SizedBox(height: 8),

              // Badge grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: filteredBadges.length,
                  itemBuilder: (context, index) {
                    final badge = filteredBadges[index];
                    final isEarned = earnedIds.contains(badge.id);
                    final earnedBadge = isEarned
                        ? state.earnedBadges.firstWhere(
                            (e) => e.badgeId == badge.id,
                          )
                        : null;

                    return BadgeCard(
                      definition: badge,
                      isEarned: isEarned,
                      earnedAt: earnedBadge?.earnedAt,
                      onTap: () => showBadgeDetailSheet(
                        context,
                        definition: badge,
                        isEarned: isEarned,
                        earnedAt: earnedBadge?.earnedAt,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  final BadgeCategory? selectedCategory;
  final ValueChanged<BadgeCategory?> onSelected;

  const _CategoryFilterRow({
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = <BadgeCategory?, String>{
      null: l10n.allCategories,
      BadgeCategory.reading: l10n.categoryReading,
      BadgeCategory.streak: l10n.categoryStreak,
      BadgeCategory.focus: l10n.categoryFocus,
      BadgeCategory.special: l10n.categorySpecial,
    };

    final categoryAvatars = <BadgeCategory?, Widget>{
      BadgeCategory.reading: AnimatedEmoji(AnimatedEmojis.nerdFace, size: 16),
      BadgeCategory.streak: AnimatedEmoji(AnimatedEmojis.fire, size: 16),
      BadgeCategory.focus: AnimatedEmoji(AnimatedEmojis.plant, size: 16),
      BadgeCategory.special: AnimatedEmoji(AnimatedEmojis.gemStone, size: 16),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.entries.map((entry) {
          final isSelected = selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: categoryAvatars[entry.key],
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) => onSelected(entry.key),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              backgroundColor: AppColors.surfaceDark,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceDark,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}
