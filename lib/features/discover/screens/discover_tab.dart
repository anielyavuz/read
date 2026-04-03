import 'dart:ui' show ImageFilter;

import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/game_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/cubit/profile_state.dart';
import '../cubit/discover_cubit.dart';
import '../cubit/discover_state.dart';
import '../models/challenge_template.dart';
import '../widgets/challenge_card.dart';
import '../widgets/template_card.dart';

/// Discover tab — cubit is provided by ShellScreen, not created here.
class DiscoverTab extends StatelessWidget {
  const DiscoverTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Check calm mode from ProfileCubit (provided by ShellScreen)
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final isCalmMode = profileState.profile?.calmMode ?? false;

        if (isCalmMode) {
          return _CalmModeOverlay();
        }

        return _buildDiscoverContent(context, l10n);
      },
    );
  }

  Widget _buildDiscoverContent(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: BlocConsumer<DiscoverCubit, DiscoverState>(
        listener: (context, state) {
          if (state.status == DiscoverStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == DiscoverStatus.loading ||
              state.status == DiscoverStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final bottomPadding =
              MediaQuery.of(context).padding.bottom + 80;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                context.read<DiscoverCubit>().refreshChallenges(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomPadding),
              children: [
                // Header
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      l10n.navDiscover,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Start Templates
                _SectionHeader(
                  title: l10n.quickStart,
                  iconWidget: const AnimatedEmoji(AnimatedEmojis.rocket, size: 20),
                ),
                const SizedBox(height: 12),
                _TemplatesRow(),
                const SizedBox(height: 28),

                // My Active Challenges
                if (state.myChallenges.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.myChallenges,
                    iconWidget: const AnimatedEmoji(AnimatedEmojis.trophy, size: 20),
                  ),
                  const SizedBox(height: 12),
                  ...state.myChallenges.map(
                    (challenge) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ChallengeCard(
                        challenge: challenge,
                        onTap: () =>
                            context.push('/challenge/${challenge.id}'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Community Challenges
                _SectionHeader(
                  title: l10n.community,
                  iconWidget: const AnimatedEmoji(AnimatedEmojis.globeShowingEuropeAfrica, size: 20),
                ),
                const SizedBox(height: 12),
                if (state.communityChallenges.isEmpty)
                  _EmptyCommunity()
                else
                  ...state.communityChallenges.map(
                    (challenge) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ChallengeCard(
                        challenge: challenge,
                        onTap: () =>
                            context.push('/challenge/${challenge.id}'),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Create custom challenge button
                _CreateCustomButton(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalmModeOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Blurred background placeholder circles
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Simulated blurred cards
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          Container(
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Overlay content
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.spa_rounded,
                            size: 56,
                            color: Color(0xFF22C55E),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.discoverCalmModeTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.discoverCalmModeMessage,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                context.read<ProfileCubit>().disableCalmMode();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                l10n.exitCalmMode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? iconWidget;

  const _SectionHeader({
    required this.title,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (iconWidget != null) iconWidget!,
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: ChallengeTemplate.templates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final template = ChallengeTemplate.templates[index];
          return TemplateCard(
            template: template,
            onTap: () => _showTemplateDialog(context, template, l10n),
          );
        },
      ),
    );
  }

  void _showTemplateDialog(
    BuildContext context,
    ChallengeTemplate template,
    AppLocalizations l10n,
  ) {
    final title = _resolveTitle(l10n, template.titleKey);
    final description = _resolveDesc(l10n, template.descriptionKey);
    final cubit = context.read<DiscoverCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Emoji
              Text(
                template.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Info chips
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: l10n.daysLabel(template.durationDays),
                    color: template.color,
                  ),
                  _InfoChip(
                    icon: Icons.group_rounded,
                    label: '30 max',
                    color: template.color,
                  ),
                  if (template.targetPages != null)
                    _InfoChip(
                      icon: Icons.auto_stories_rounded,
                      label: '${template.targetPages} ${l10n.targetPages.toLowerCase()}',
                      color: template.color,
                    ),
                  if (template.targetBooks != null)
                    _InfoChip(
                      icon: Icons.menu_book_rounded,
                      label: '${template.targetBooks} ${l10n.targetBooks.toLowerCase()}',
                      color: template.color,
                    ),
                  if (template.targetMinutes != null)
                    _InfoChip(
                      icon: Icons.timer_rounded,
                      label: '${template.targetMinutes} min',
                      color: template.color,
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    cubit.createFromTemplate(
                      title: title,
                      description: description,
                      type: template.type,
                      targetPages: template.targetPages,
                      targetBooks: template.targetBooks,
                      targetMinutes: template.targetMinutes,
                      durationDays: template.durationDays,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.challengeStarted),
                        backgroundColor: const Color(0xFF22C55E),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: template.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          size: 24, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.startChallenge,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  static String _resolveTitle(AppLocalizations l10n, String key) {
    switch (key) {
      case 'templateWeekendSprint':
        return l10n.templateWeekendSprint;
      case 'templatePageTurner':
        return l10n.templatePageTurner;
      case 'templateGenreExplorer':
        return l10n.templateGenreExplorer;
      case 'templateSpeedReader':
        return l10n.templateSpeedReader;
      case 'templateBookClub':
        return l10n.templateBookClub;
      case 'templateFocusMarathon':
        return l10n.templateFocusMarathon;
      default:
        return key;
    }
  }

  static String _resolveDesc(AppLocalizations l10n, String key) {
    switch (key) {
      case 'templateWeekendSprintDesc':
        return l10n.templateWeekendSprintDesc;
      case 'templatePageTurnerDesc':
        return l10n.templatePageTurnerDesc;
      case 'templateGenreExplorerDesc':
        return l10n.templateGenreExplorerDesc;
      case 'templateSpeedReaderDesc':
        return l10n.templateSpeedReaderDesc;
      case 'templateBookClubDesc':
        return l10n.templateBookClubDesc;
      case 'templateFocusMarathonDesc':
        return l10n.templateFocusMarathonDesc;
      default:
        return key;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCommunity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const AnimatedEmoji(AnimatedEmojis.crystalBall, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.noChallengesYet,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.noChallengesJoined,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCustomButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.or,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GameButton(
            onTap: () => context.push('/create-challenge'),
            color: AppColors.surfaceDark,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            shadowHeight: 5,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 22, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.createCustomChallenge,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
