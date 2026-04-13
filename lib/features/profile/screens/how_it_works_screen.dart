import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        title: Text(
          l10n.howItWorks,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _ExpandableSection(
              icon: Icons.star_rounded,
              iconColor: AppColors.amber,
              iconWidget: AnimatedEmoji(AnimatedEmojis.sparkles, size: 22),
              title: l10n.guideXpTitle,
              content: l10n.guideXpContent,
            ),
            const SizedBox(height: 12),
            _ExpandableSection(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orangeAccent,
              iconWidget: AnimatedEmoji(AnimatedEmojis.fire, size: 22),
              title: l10n.guideStreakTitle,
              content: l10n.guideStreakContent,
            ),
            const SizedBox(height: 12),
            _ExpandableSection(
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.amber,
              iconWidget: AnimatedEmoji(AnimatedEmojis.trophy, size: 22),
              title: l10n.guideLeagueTitle,
              content: l10n.guideLeagueContent,
            ),
            const SizedBox(height: 12),
            _ExpandableSection(
              icon: Icons.military_tech_rounded,
              iconColor: AppColors.primaryLight,
              iconWidget: AnimatedEmoji(AnimatedEmojis.goldMedal, size: 22),
              title: l10n.guideBadgeTitle,
              content: l10n.guideBadgeContent,
            ),
            const SizedBox(height: 12),
            _ExpandableSection(
              icon: Icons.timer_rounded,
              iconColor: Colors.tealAccent,
              iconWidget: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 22),
              title: l10n.guideFocusTitle,
              content: l10n.guideFocusContent,
            ),
            const SizedBox(height: 12),
            _ExpandableSection(
              icon: Icons.flag_rounded,
              iconColor: const Color(0xFF22C55E),
              iconWidget: AnimatedEmoji(AnimatedEmojis.chequeredFlag, size: 22),
              title: l10n.guideChallengeTitle,
              content: l10n.guideChallengeContent,
            ),
            const SizedBox(height: 12),
            _ExpandableSection(
              icon: Icons.psychology_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconWidget: AnimatedEmoji(AnimatedEmojis.nerdFace, size: 22),
              title: l10n.guideReadBrainTitle,
              content: l10n.guideReadBrainContent,
            ),
            const SizedBox(height: 12),
            _ExpandableSection(
              icon: Icons.camera_alt_rounded,
              iconColor: const Color(0xFF06B6D4),
              iconWidget: AnimatedEmoji(AnimatedEmojis.cameraFlash, size: 22),
              title: l10n.guideAiScannerTitle,
              content: l10n.guideAiScannerContent,
            ),
            const SizedBox(height: 12),
            _ExpandableSection(
              icon: Icons.spa_rounded,
              iconColor: const Color(0xFF10B981),
              iconWidget: AnimatedEmoji(AnimatedEmojis.relieved, size: 22),
              title: l10n.guideCalmModeTitle,
              content: l10n.guideCalmModeContent,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Widget? iconWidget;
  final String title;
  final String content;

  const _ExpandableSection({
    required this.icon,
    required this.iconColor,
    this.iconWidget,
    required this.title,
    required this.content,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                widget.iconWidget ??
                    Icon(widget.icon, color: widget.iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
