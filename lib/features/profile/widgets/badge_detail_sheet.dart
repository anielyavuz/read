import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/models/badge.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../utils/badge_l10n_helper.dart';
import 'badge_card.dart';

/// Shows a modal bottom sheet with full badge details.
void showBadgeDetailSheet(
  BuildContext context, {
  required BadgeDefinition definition,
  required bool isEarned,
  DateTime? earnedAt,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _BadgeDetailContent(
      definition: definition,
      isEarned: isEarned,
      earnedAt: earnedAt,
    ),
  );
}

class _BadgeDetailContent extends StatelessWidget {
  final BadgeDefinition definition;
  final bool isEarned;
  final DateTime? earnedAt;

  const _BadgeDetailContent({
    required this.definition,
    required this.isEarned,
    this.earnedAt,
  });

  String _categoryLabel(AppLocalizations l10n, BadgeCategory category) {
    switch (category) {
      case BadgeCategory.reading:
        return l10n.categoryReading;
      case BadgeCategory.streak:
        return l10n.categoryStreak;
      case BadgeCategory.focus:
        return l10n.categoryFocus;
      case BadgeCategory.special:
        return l10n.categorySpecial;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badgeName = resolveBadgeL10n(l10n, definition.nameKey);
    final badgeDesc = resolveBadgeL10n(l10n, definition.descriptionKey);
    final accent = BadgeCard.categoryColor(definition.category);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Large emoji
            Text(
              definition.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),

            // Badge name
            Text(
              badgeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              badgeDesc,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Earned date or motivational text
            if (isEarned && earnedAt != null) ...[
              Text(
                l10n.badgeEarnedOn(DateFormat.yMMMd().format(earnedAt!)),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _categoryLabel(l10n, definition.category),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action area
            if (isEarned)
              OutlinedButton.icon(
                onPressed: () {
                  Haptics.light();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.shareComingSoon),
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(l10n.shareBadge),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              )
            else
              Text(
                l10n.keepReadingToUnlock,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
