import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/league.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/home_challenges_card.dart';
import '../widgets/home_reader_profile_card.dart';
import '../widgets/reading_journey_path.dart';

/// Home tab — cubit is provided by ShellScreen, not created here.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  void _pushAndRefresh(String path) {
    final cubit = context.read<HomeCubit>();
    context.push(path).then((_) {
      if (mounted) cubit.refreshHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) {
          if (state.status == HomeStatus.loaded && state.userProfile != null) {
            final cubit = context.read<HomeCubit>();
            final remaining = state.userProfile!.dailyGoalPages - state.pagesReadToday;

            // Schedule daily goal reminder with localized strings
            cubit.scheduleDailyGoalNotification(
              title: l10n.dailyGoalNotifTitle,
              body: l10n.dailyGoalNotifBody(remaining),
            );

            // Refresh reading reminders with correct locale
            cubit.refreshReadingReminders(
              title: l10n.readingReminderNotifTitle,
              body: l10n.readingReminderNotifBody,
            );
          }
        },
        builder: (context, state) {
          if (state.status == HomeStatus.loading ||
              state.status == HomeStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == HomeStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage ?? l10n.somethingWentWrong,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.read<HomeCubit>().refreshHome(),
                    child: Text(
                      l10n.retry,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }

          final profile = state.userProfile;
          if (profile == null) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<HomeCubit>().refreshHome(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Greeting + League medallion + action buttons
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // League medallion (hidden in calm mode)
                        if (!profile.calmMode) ...[
                          _leagueMedallion(profile.currentLeague),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(context, profile.displayName),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.readyForToday,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Social buttons (hidden in calm mode)
                        if (!profile.calmMode)
                          Row(
                            children: [
                              _inboxButton(state.unreadInboxCount),
                              const SizedBox(width: 8),
                              _friendsButton(state.pendingFriendRequests),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Daily progress card (hidden in calm mode)
                    if (!profile.calmMode) ...[
                      DailyProgressCard(
                        profile: profile,
                        pagesReadToday: state.pagesReadToday,
                        onTap: () => _pushAndRefresh('/streak'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Active challenges (hidden in calm mode)
                    if (!profile.calmMode) ...[
                      HomeChallengesCard(
                        challenges: state.myChallenges,
                        onDiscover: () => context.go('/discover'),
                        onChallengeTap: (id) =>
                            _pushAndRefresh('/challenge/$id'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Reader profile card
                    HomeReaderProfileCard(
                      profile: state.readerProfile,
                      onTap: () {
                        if (state.readerProfile != null) {
                          _pushAndRefresh('/reader-profile-detail');
                        } else {
                          _pushAndRefresh('/reader-profile-quiz');
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Reading Journey Path
                    ReadingJourneyPath(
                      entries: state.activityEntries,
                      onContinue: () => context.go('/focus'),
                      onDeleteEntry: (entryId) {
                        context.read<HomeCubit>().deleteActivity(entryId);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _leagueMedallion(String currentLeague) {
    final tier = tierFromString(currentLeague);

    AnimatedEmojiData tierEmoji;
    switch (tier) {
      case LeagueTier.bronze:
        tierEmoji = AnimatedEmojis.bronzeMedal;
      case LeagueTier.silver:
        tierEmoji = AnimatedEmojis.silverMedal;
      case LeagueTier.gold:
        tierEmoji = AnimatedEmojis.goldMedal;
      case LeagueTier.platinum:
        tierEmoji = AnimatedEmojis.trophy;
      case LeagueTier.diamond:
        tierEmoji = AnimatedEmojis.gemStone;
    }

    return GestureDetector(
      onTap: () => _pushAndRefresh('/league'),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceDark,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedEmoji(tierEmoji, size: 26),
        ),
      ),
    );
  }

  Widget _inboxButton(int unreadCount) {
    return GestureDetector(
      onTap: () => _pushAndRefresh('/inbox'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mail_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _friendsButton(int pendingCount) {
    return GestureDetector(
      onTap: () => _pushAndRefresh('/friends'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          if (pendingCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _greeting(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final firstName = name.split(' ').first;

    if (hour < 12) {
      return l10n.goodMorning(firstName);
    } else if (hour < 17) {
      return l10n.goodAfternoon(firstName);
    } else {
      return l10n.goodEvening(firstName);
    }
  }
}
