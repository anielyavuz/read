import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/badge_definitions.dart';
import '../../../core/models/badge.dart';
import '../../../l10n/generated/app_localizations.dart';

class BadgePreviewRow extends StatelessWidget {
  final List<EarnedBadge> earnedBadges;

  const BadgePreviewRow({super.key, required this.earnedBadges});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.badgeCollection,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/badges'),
                child: Text(
                  '${l10n.viewAllBadges} >',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (earnedBadges.isEmpty)
            Text(
              l10n.noBadgesYet,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            )
          else
            Row(
              children: earnedBadges.take(5).map((earned) {
                final definition = allBadges
                    .where((b) => b.id == earned.badgeId)
                    .firstOrNull;
                final emoji = definition?.icon ?? '?';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
