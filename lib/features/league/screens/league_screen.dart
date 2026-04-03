import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/league.dart';
import '../../../core/services/friendship_service.dart';
import '../../../core/services/league_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/league_cubit.dart';
import '../cubit/league_state.dart';

class LeagueScreen extends StatelessWidget {
  const LeagueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeagueCubit>()..loadLeague(),
      child: const _LeagueScreenContent(),
    );
  }
}

class _LeagueScreenContent extends StatelessWidget {
  const _LeagueScreenContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: BlocBuilder<LeagueCubit, LeagueState>(
          buildWhen: (prev, curr) => prev.currentTier != curr.currentTier,
          builder: (context, state) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: _tierColor(state.currentTier),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_tierName(l10n, state.currentTier)} ${l10n.weeklyLeague}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: () => _showLeagueInfo(context),
          ),
        ],
      ),
      body: BlocBuilder<LeagueCubit, LeagueState>(
        builder: (context, state) {
          if (state.status == LeagueStatus.loading ||
              state.status == LeagueStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == LeagueStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<LeagueCubit>().loadLeague(),
                    child: Text(
                      l10n.retry,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                context.read<LeagueCubit>().refreshLeaderboard(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Tier badge
                _TierBadge(tier: state.currentTier),
                const SizedBox(height: 16),

                // My rank card
                if (state.myEntry != null)
                  _MyRankCard(
                    entry: state.myEntry!,
                    leaderboardSize: state.leaderboard.length,
                    tier: state.currentTier,
                  ),
                const SizedBox(height: 16),

                // Friends reading section
                if (state.friendsReading.isNotEmpty) ...[
                  _FriendsReadingSection(friends: state.friendsReading),
                  const SizedBox(height: 16),
                ],

                // Leaderboard header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.leaderboard,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Leaderboard rows
                ...List.generate(state.leaderboard.length, (index) {
                  final participant = state.leaderboard[index];
                  final rank = index + 1;
                  final isMe = state.myEntry?.userId == participant.userId;
                  final isPromotion =
                      rank <= getIt<LeagueService>().getPromotionZone();
                  final isRelegation =
                      state.currentTier != LeagueTier.diamond &&
                          rank >
                              state.leaderboard.length -
                                  getIt<LeagueService>().getRelegationZone();

                  return _LeaderboardRow(
                    participant: participant,
                    rank: rank,
                    isMe: isMe,
                    isPromotion: isPromotion,
                    isRelegation: isRelegation,
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLeagueInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.leagueInfoTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tiers
              _InfoSection(
                title: l10n.leagueInfoTiers,
                content: l10n.leagueInfoTiersContent,
              ),
              const SizedBox(height: 16),

              // How XP works
              _InfoSection(
                title: l10n.leagueInfoHowXp,
                content: l10n.leagueInfoHowXpContent,
              ),
              const SizedBox(height: 16),

              // Rules
              _InfoSection(
                title: l10n.leagueInfoRules,
                content: l10n.leagueInfoRulesContent,
              ),
              const SizedBox(height: 16),

              // Tip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.leagueInfoTip,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Close button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.dismiss,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _tierColor(LeagueTier tier) {
    switch (tier) {
      case LeagueTier.bronze:
        return const Color(0xFFCD7F32);
      case LeagueTier.silver:
        return const Color(0xFFC0C0C0);
      case LeagueTier.gold:
        return const Color(0xFFFFD700);
      case LeagueTier.platinum:
        return const Color(0xFFE5E4E2);
      case LeagueTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  static String _tierName(AppLocalizations l10n, LeagueTier tier) {
    switch (tier) {
      case LeagueTier.bronze:
        return l10n.leagueBronze;
      case LeagueTier.silver:
        return l10n.leagueSilver;
      case LeagueTier.gold:
        return l10n.leagueGold;
      case LeagueTier.platinum:
        return l10n.leaguePlatinum;
      case LeagueTier.diamond:
        return l10n.leagueDiamond;
    }
  }
}

class _TierBadge extends StatelessWidget {
  final LeagueTier tier;

  const _TierBadge({required this.tier});

  int _weekDay() {
    final now = DateTime.now();
    // Monday=1 … Sunday=7
    return now.weekday;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _LeagueScreenContent._tierColor(tier);
    final name = _LeagueScreenContent._tierName(l10n, tier);
    final currentIndex = LeagueTier.values.indexOf(tier);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Current tier name + day
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.leagueWeekDay(_weekDay()),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // All tiers in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(LeagueTier.values.length, (index) {
              final t = LeagueTier.values[index];
              final tColor = _LeagueScreenContent._tierColor(t);
              final isCurrent = index == currentIndex;
              final isLocked = index > currentIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Container(
                      width: isCurrent ? 52 : 40,
                      height: isCurrent ? 52 : 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? tColor.withValues(alpha: 0.15)
                            : isLocked
                                ? AppColors.textMuted.withValues(alpha: 0.08)
                                : tColor.withValues(alpha: 0.08),
                        border: isCurrent
                            ? Border.all(color: tColor, width: 2)
                            : null,
                      ),
                      child: Icon(
                        isLocked
                            ? Icons.lock_rounded
                            : Icons.shield_rounded,
                        size: isCurrent ? 26 : 20,
                        color: isLocked
                            ? AppColors.textMuted.withValues(alpha: 0.3)
                            : isCurrent
                                ? tColor
                                : tColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _LeagueScreenContent._tierName(l10n, t),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isLocked
                            ? AppColors.textMuted.withValues(alpha: 0.4)
                            : isCurrent
                                ? tColor
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  final LeagueParticipant entry;
  final int leaderboardSize;
  final LeagueTier tier;

  const _MyRankCard({
    required this.entry,
    required this.leaderboardSize,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final leagueService = getIt<LeagueService>();

    // Determine zone
    final myRankIndex = entry.rank > 0 ? entry.rank : leaderboardSize;
    final isPromotion = myRankIndex <= leagueService.getPromotionZone();
    final isRelegation = tier != LeagueTier.diamond &&
        myRankIndex >
            leaderboardSize - leagueService.getRelegationZone();

    String zoneText;
    Color zoneColor;
    if (isPromotion) {
      zoneText = l10n.promotionZone;
      zoneColor = const Color(0xFF22C55E);
    } else if (isRelegation) {
      zoneText = l10n.relegationZone;
      zoneColor = const Color(0xFFEF4444);
    } else {
      zoneText = l10n.safeZone;
      zoneColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$myRankIndex',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourRank,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.xpEarned} XP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPromotion)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedEmoji(AnimatedEmojis.rocket, size: 14),
                  ),
                if (isRelegation)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedEmoji(AnimatedEmojis.warning, size: 14),
                  ),
                Text(
                  zoneText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: zoneColor,
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

class _LeaderboardRow extends StatelessWidget {
  final LeagueParticipant participant;
  final int rank;
  final bool isMe;
  final bool isPromotion;
  final bool isRelegation;

  const _LeaderboardRow({
    required this.participant,
    required this.rank,
    required this.isMe,
    required this.isPromotion,
    required this.isRelegation,
  });

  @override
  Widget build(BuildContext context) {
    Color? borderColor;
    if (isPromotion) {
      borderColor = const Color(0xFF22C55E);
    } else if (isRelegation) {
      borderColor = const Color(0xFFEF4444);
    }

    final initial = participant.displayName.isNotEmpty
        ? participant.displayName[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: isMe
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Left zone indicator
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: borderColor ?? Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Rank number or medal emoji for top 3
          SizedBox(
            width: 28,
            child: rank == 1
                ? AnimatedEmoji(AnimatedEmojis.goldMedal, size: 20)
                : rank == 2
                    ? AnimatedEmoji(AnimatedEmojis.silverMedal, size: 20)
                    : rank == 3
                        ? AnimatedEmoji(AnimatedEmojis.bronzeMedal, size: 20)
                        : Text(
                            '$rank',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
          ),
          const SizedBox(width: 8),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe
                ? AppColors.primary
                : AppColors.textMuted.withValues(alpha: 0.3),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name
          Expanded(
            child: Text(
              participant.displayName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // XP
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              '${participant.xpEarned} XP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isMe ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsReadingSection extends StatelessWidget {
  final List<FriendWithProfile> friends;

  const _FriendsReadingSection({required this.friends});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.friendsReading,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _FriendReadingCard(friend: friends[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _FriendReadingCard extends StatelessWidget {
  final FriendWithProfile friend;

  const _FriendReadingCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = friend.profile;
    final book = friend.currentlyReading.first;
    final initial = profile.displayName.isNotEmpty
        ? profile.displayName[0].toUpperCase()
        : '?';
    final progress = book.totalPages > 0
        ? (book.currentPage / book.totalPages).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Friend name
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Book title
          Text(
            book.title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Progress bar + page count
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor:
                        AppColors.textMuted.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                book.totalPages > 0
                    ? l10n.pageProgress(book.currentPage, book.totalPages)
                    : '${book.currentPage}p',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const _InfoSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
