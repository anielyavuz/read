import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../l10n/generated/app_localizations.dart';

class DailyProgressCard extends StatelessWidget {
  final UserProfile profile;
  final int pagesReadToday;
  final VoidCallback? onTap;

  const DailyProgressCard({
    super.key,
    required this.profile,
    required this.pagesReadToday,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dailyGoal = profile.dailyGoalPages;
    final progress = dailyGoal > 0
        ? (pagesReadToday / dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    return GameButton(
      onTap: onTap,
      color: AppColors.surfaceDark,
      shadowColor: AppColors.amber.withValues(alpha: 0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mascot cat — small static image
          const MascotWidget(size: 56, showGlow: false),
          const SizedBox(width: 14),

          // Stats column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak / prompt + XP
                if (profile.streakDays > 0) ...[
                  Row(
                    children: [
                      const AnimatedEmoji(AnimatedEmojis.fire, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        l10n.dayStreak(profile.streakDays),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amber,
                        ),
                      ),
                      const Spacer(),
                      const AnimatedEmoji(AnimatedEmojis.sparkles, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        l10n.xpTotal(profile.xpTotal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // XP on the right, same line
                  Row(
                    children: [
                      const AnimatedEmoji(AnimatedEmojis.fire, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        l10n.streakStartPrompt,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amber,
                        ),
                      ),
                      const Spacer(),
                      const AnimatedEmoji(AnimatedEmojis.sparkles, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        l10n.xpTotal(profile.xpTotal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),

                // Progress label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.dailyProgress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      l10n.pagesProgress(pagesReadToday, dailyGoal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar
                AnimatedProgressBar(
                  value: progress,
                  height: 10,
                  gradientColors: const [
                    AppColors.primary,
                    Color(0xFF8B5CF6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
