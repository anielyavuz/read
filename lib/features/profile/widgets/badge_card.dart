import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/badge.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../utils/badge_l10n_helper.dart';

class BadgeCard extends StatelessWidget {
  final BadgeDefinition definition;
  final bool isEarned;
  final DateTime? earnedAt;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.definition,
    required this.isEarned,
    this.earnedAt,
    this.onTap,
  });

  static Color categoryColor(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.reading:
        return AppColors.primary;
      case BadgeCategory.streak:
        return const Color(0xFFF59E0B);
      case BadgeCategory.focus:
        return const Color(0xFF14B8A6);
      case BadgeCategory.special:
        return const Color(0xFFEC4899);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = categoryColor(definition.category);
    final badgeName = resolveBadgeL10n(l10n, definition.nameKey);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: isEarned
              ? AppColors.surfaceDark
              : AppColors.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Category accent line at top
            Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isEarned ? accent : accent.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon area
                    if (isEarned)
                      Text(
                        definition.icon,
                        style: const TextStyle(fontSize: 32),
                      )
                    else
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 0.3,
                            child: Text(
                              definition.icon,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // Badge name
                    Text(
                      badgeName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isEarned
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
