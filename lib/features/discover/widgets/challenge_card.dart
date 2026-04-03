import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/models/challenge.dart';
import '../../../l10n/generated/app_localizations.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeColor = _typeColor(challenge.type);
    final typeIcon = _typeIcon(challenge.type);
    final typeLabel = _typeLabel(l10n, challenge.type);

    // Calculate time remaining (date-only comparison for accuracy)
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final endDateOnly = DateTime(challenge.endDate.year, challenge.endDate.month, challenge.endDate.day);
    final daysLeft = endDateOnly.difference(todayDate).inDays;
    final hasEnded = now.isAfter(challenge.endDate);
    final timeText = hasEnded
        ? l10n.challengeDetailEnded
        : daysLeft == 0
            ? l10n.challengeDetailEndsToday
            : l10n.challengeEndsIn(daysLeft);

    // Progress ratio
    final progressRatio = challenge.maxParticipants > 0
        ? challenge.currentParticipants / challenge.maxParticipants
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GameButton(
        onTap: onTap,
        color: AppColors.surfaceDark,
        shadowColor: typeColor.withValues(alpha: 0.25),
        shadowHeight: 4,
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type icon with color
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Title and type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: typeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time remaining
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasEnded
                        ? AppColors.textMuted.withValues(alpha: 0.15)
                        : typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasEnded ? AppColors.textMuted : typeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Participants count and progress
            Row(
              children: [
                Icon(
                  Icons.group_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.participantsCount(
                    challenge.currentParticipants,
                    challenge.maxParticipants,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            AnimatedProgressBar(
              value: progressRatio,
              height: 4,
              gradientColors: [
                typeColor,
                typeColor.withValues(alpha: 0.7),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _typeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.readAlong:
        return const Color(0xFF22C55E);
      case ChallengeType.sprint:
        return const Color(0xFFF59E0B);
      case ChallengeType.genre:
        return const Color(0xFF8B5CF6);
      case ChallengeType.pages:
        return const Color(0xFF06B6D4);
    }
  }

  static IconData _typeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.readAlong:
        return Icons.menu_book_rounded;
      case ChallengeType.sprint:
        return Icons.speed_rounded;
      case ChallengeType.genre:
        return Icons.category_rounded;
      case ChallengeType.pages:
        return Icons.auto_stories_rounded;
    }
  }

  static String _typeLabel(AppLocalizations l10n, ChallengeType type) {
    switch (type) {
      case ChallengeType.readAlong:
        return l10n.challengeTypeReadAlong;
      case ChallengeType.sprint:
        return l10n.challengeTypeSprint;
      case ChallengeType.genre:
        return l10n.challengeTypeGenre;
      case ChallengeType.pages:
        return l10n.challengeTypePages;
    }
  }
}
