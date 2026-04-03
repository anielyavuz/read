import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/challenge.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Compact challenge strip for the home page.
///
/// Shows active challenges as slim horizontal cards with progress.
/// If no challenges, shows a single motivating CTA to discover page.
class HomeChallengesCard extends StatelessWidget {
  final List<Challenge> challenges;
  final VoidCallback onDiscover;
  final void Function(String challengeId) onChallengeTap;

  const HomeChallengesCard({
    super.key,
    required this.challenges,
    required this.onDiscover,
    required this.onChallengeTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (challenges.isEmpty) {
      return _buildEmpty(context, l10n);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Text(
              l10n.homeChallengesTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onDiscover,
              child: Text(
                l10n.viewAll,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Challenge list (max 3)
        ...challenges.take(3).map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChallengeRow(
                challenge: c,
                onTap: () => onChallengeTap(c.id),
              ),
            )),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: onDiscover,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Color(0xFF8B5CF6),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeNoChallenges,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.homeJoinChallenge,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const _ChallengeRow({required this.challenge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Use date-only comparison for accurate day count
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final endDateOnly = DateTime(challenge.endDate.year, challenge.endDate.month, challenge.endDate.day);
    final daysLeft = endDateOnly.difference(todayDate).inDays;
    final hasEnded = now.isAfter(challenge.endDate);
    final typeConfig = _typeConfig(challenge.type);

    final targetLabel = _targetLabel(challenge, l10n);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: typeConfig.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeConfig.icon, color: typeConfig.color, size: 18),
            ),
            const SizedBox(width: 10),

            // Title + target
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    targetLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Days left pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hasEnded
                    ? AppColors.textMuted.withValues(alpha: 0.15)
                    : daysLeft <= 2
                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                        : typeConfig.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasEnded
                    ? l10n.challengeDetailEnded
                    : daysLeft == 0
                        ? l10n.challengeDetailEndsToday
                        : l10n.challengeEndsIn(daysLeft),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: hasEnded
                      ? AppColors.textMuted
                      : daysLeft <= 2
                          ? const Color(0xFFEF4444)
                          : typeConfig.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(Challenge c, AppLocalizations l10n) {
    switch (c.type) {
      case ChallengeType.pages:
      case ChallengeType.readAlong:
        return '${c.targetPages ?? 0} ${l10n.pages}';
      case ChallengeType.sprint:
        return '${c.targetMinutes ?? 0} ${l10n.journeyMin}';
      case ChallengeType.genre:
        return '${c.targetBooks ?? 0} ${l10n.booksReadStat.toLowerCase()}';
    }
  }

  _TypeConfig _typeConfig(ChallengeType type) {
    switch (type) {
      case ChallengeType.readAlong:
        return _TypeConfig(Icons.menu_book_rounded, const Color(0xFF22C55E));
      case ChallengeType.sprint:
        return _TypeConfig(Icons.bolt_rounded, const Color(0xFFF59E0B));
      case ChallengeType.genre:
        return _TypeConfig(Icons.category_rounded, const Color(0xFF8B5CF6));
      case ChallengeType.pages:
        return _TypeConfig(Icons.auto_stories_rounded, const Color(0xFF06B6D4));
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  const _TypeConfig(this.icon, this.color);
}
