import 'package:animated_emoji/animated_emoji.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/models/challenge.dart';
import '../../../core/services/friendship_service.dart';
import '../../../core/services/inbox_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/challenge_detail_cubit.dart';
import '../cubit/challenge_detail_state.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final String challengeId;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ChallengeDetailCubit>()..loadChallenge(challengeId),
      child: _ChallengeDetailContent(challengeId: challengeId),
    );
  }
}

class _ChallengeDetailContent extends StatelessWidget {
  final String challengeId;

  const _ChallengeDetailContent({required this.challengeId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: BlocBuilder<ChallengeDetailCubit, ChallengeDetailState>(
          buildWhen: (prev, curr) =>
              prev.challenge?.title != curr.challenge?.title,
          builder: (context, state) {
            return Text(
              state.challenge?.title ?? l10n.challenges,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        actions: [
          BlocBuilder<ChallengeDetailCubit, ChallengeDetailState>(
            buildWhen: (prev, curr) =>
                prev.isParticipating != curr.isParticipating,
            builder: (context, state) {
              if (!state.isParticipating || state.challenge == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: () => _showInviteFriends(
                    context, state.challenge!),
                icon: const Icon(Icons.person_add_rounded),
                color: AppColors.primary,
                tooltip: l10n.inviteFriends,
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ChallengeDetailCubit, ChallengeDetailState>(
        listener: (context, state) {
          if (state.status == ChallengeDetailStatus.error &&
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
          if (state.status == ChallengeDetailStatus.loading ||
              state.status == ChallengeDetailStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == ChallengeDetailStatus.error &&
              state.challenge == null) {
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
                    onPressed: () => context
                        .read<ChallengeDetailCubit>()
                        .loadChallenge(challengeId),
                    child: Text(
                      l10n.retry,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }

          final challenge = state.challenge!;
          final typeColor = _typeColor(challenge.type);
          final typeLabel = _typeLabel(l10n, challenge.type);
          final isFull = challenge.currentParticipants >=
              challenge.maxParticipants;
          final isJoiningOrLeaving =
              state.status == ChallengeDetailStatus.joining ||
                  state.status == ChallengeDetailStatus.leaving;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // ── Header card with type, status, dates ──
                    _buildHeaderCard(context, l10n, challenge, typeColor, typeLabel),
                    const SizedBox(height: 12),

                    // ── Progress card (only if participating) ──
                    if (state.isParticipating)
                      _buildProgressCard(context, l10n, challenge, state, typeColor),
                    if (state.isParticipating)
                      const SizedBox(height: 12),

                    // ── Leaderboard ──
                    _buildLeaderboard(context, l10n, challenge, state, typeColor),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Bottom action button
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: _buildActionButton(
                      context,
                      l10n,
                      state.isParticipating,
                      isFull,
                      isJoiningOrLeaving,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Header card ──
  Widget _buildHeaderCard(
    BuildContext context,
    AppLocalizations l10n,
    Challenge challenge,
    Color typeColor,
    String typeLabel,
  ) {
    final dateFormat = DateFormat('MMM d');
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final endDateOnly = DateTime(challenge.endDate.year, challenge.endDate.month, challenge.endDate.day);
    final startDateOnly = DateTime(challenge.startDate.year, challenge.startDate.month, challenge.startDate.day);
    final daysLeft = endDateOnly.difference(todayDate).inDays;
    final totalDays = endDateOnly.difference(startDateOnly).inDays;
    final elapsedDays = todayDate.difference(startDateOnly).inDays;
    final timeProgress = totalDays > 0 ? (elapsedDays / totalDays).clamp(0.0, 1.0) : 1.0;

    // Status label
    String statusLabel;
    Color statusColor;
    if (daysLeft < 0) {
      statusLabel = l10n.challengeDetailEnded;
      statusColor = AppColors.textMuted;
    } else if (daysLeft == 0) {
      statusLabel = l10n.challengeDetailEndsToday;
      statusColor = const Color(0xFFEF4444);
    } else if (todayDate.isBefore(startDateOnly)) {
      statusLabel = l10n.challengeDetailStartsIn(startDateOnly.difference(todayDate).inDays);
      statusColor = AppColors.primary;
    } else {
      statusLabel = l10n.challengeDetailDaysRemaining(daysLeft);
      statusColor = daysLeft <= 2 ? const Color(0xFFEF4444) : typeColor;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + status pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon(challenge.type), size: 14, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description
          if (challenge.description.isNotEmpty) ...[
            Text(
              challenge.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Date range with time progress bar
          Row(
            children: [
              Text(
                dateFormat.format(challenge.startDate),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: timeProgress,
                    minHeight: 4,
                    backgroundColor: AppColors.textMuted.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      typeColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(challenge.endDate),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info chips row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (challenge.targetPages != null)
                _InfoChip(
                  icon: Icons.auto_stories_rounded,
                  text: '${challenge.targetPages} ${l10n.challengeDetailPagesUnit}',
                  color: typeColor,
                ),
              if (challenge.targetMinutes != null)
                _InfoChip(
                  icon: Icons.timer_rounded,
                  text: '${challenge.targetMinutes} ${l10n.challengeDetailMinutesUnit}',
                  color: typeColor,
                ),
              if (challenge.targetBooks != null)
                _InfoChip(
                  icon: Icons.menu_book_rounded,
                  text: '${challenge.targetBooks} ${l10n.challengeDetailBooksUnit}',
                  color: typeColor,
                ),
              _InfoChip(
                icon: Icons.people_rounded,
                text: '${challenge.currentParticipants}/${challenge.maxParticipants}',
                color: AppColors.textSecondary,
              ),
              if (challenge.bookTitle != null)
                _InfoChip(
                  icon: Icons.book_rounded,
                  text: challenge.bookTitle!,
                  color: typeColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress card ──
  Widget _buildProgressCard(
    BuildContext context,
    AppLocalizations l10n,
    Challenge challenge,
    ChallengeDetailState state,
    Color typeColor,
  ) {
    final target = _getTarget(challenge);
    final progress = state.myProgress;
    final progressRatio = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final isCompleted = target > 0 && progress >= target;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : typeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.trending_up_rounded,
                size: 18,
                color: isCompleted ? const Color(0xFF22C55E) : typeColor,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.challengeDetailYourProgress,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.challengeDetailCompleted,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$progress',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isCompleted ? const Color(0xFF22C55E) : typeColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ $target ${_getUnit(challenge, l10n)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(progressRatio * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? const Color(0xFF22C55E) : typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              backgroundColor: AppColors.textMuted.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? const Color(0xFF22C55E) : typeColor,
              ),
            ),
          ),

          if (progress == 0) ...[
            const SizedBox(height: 10),
            Text(
              l10n.challengeDetailNotStarted,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Leaderboard ──
  Widget _buildLeaderboard(
    BuildContext context,
    AppLocalizations l10n,
    Challenge challenge,
    ChallengeDetailState state,
    Color typeColor,
  ) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final target = _getTarget(challenge);
    final unit = _getUnit(challenge, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.leaderboard_rounded, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                l10n.challengeDetailLeaderboard,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                l10n.participantsCount(
                  challenge.currentParticipants,
                  challenge.maxParticipants,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // Participant list
        ...List.generate(state.participants.length, (index) {
          final participant = state.participants[index];
          final isMe = participant.userId == uid;
          final initial = participant.displayName.isNotEmpty
              ? participant.displayName[0].toUpperCase()
              : '?';
          final participantProgress = target > 0
              ? (participant.progress / target).clamp(0.0, 1.0)
              : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? typeColor.withValues(alpha: 0.08)
                  : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: isMe
                  ? Border.all(color: typeColor.withValues(alpha: 0.2))
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 28,
                      child: _buildRank(participant.rank),
                    ),
                    const SizedBox(width: 10),

                    // Avatar
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isMe
                          ? typeColor.withValues(alpha: 0.2)
                          : AppColors.textMuted.withValues(alpha: 0.2),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isMe ? typeColor : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Name
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              participant.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.challengeDetailYou,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: typeColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Progress value
                    Text(
                      '${participant.progress} $unit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMe ? typeColor : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Mini progress bar per participant
                if (target > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: participantProgress,
                      minHeight: 3,
                      backgroundColor: AppColors.textMuted.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMe
                            ? typeColor.withValues(alpha: 0.7)
                            : AppColors.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRank(int rank) {
    if (rank == 1) return const AnimatedEmoji(AnimatedEmojis.goldMedal, size: 18);
    if (rank == 2) return const AnimatedEmoji(AnimatedEmojis.silverMedal, size: 18);
    if (rank == 3) return const AnimatedEmoji(AnimatedEmojis.bronzeMedal, size: 18);
    return Text(
      '#$rank',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),
    );
  }

  int _getTarget(Challenge challenge) {
    switch (challenge.type) {
      case ChallengeType.pages:
      case ChallengeType.readAlong:
        return challenge.targetPages ?? 0;
      case ChallengeType.sprint:
        return challenge.targetMinutes ?? 0;
      case ChallengeType.genre:
        return challenge.targetBooks ?? 0;
    }
  }

  String _getUnit(Challenge challenge, AppLocalizations l10n) {
    switch (challenge.type) {
      case ChallengeType.pages:
      case ChallengeType.readAlong:
        return l10n.challengeDetailPagesUnit;
      case ChallengeType.sprint:
        return l10n.challengeDetailMinutesUnit;
      case ChallengeType.genre:
        return l10n.challengeDetailBooksUnit;
    }
  }

  IconData _typeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.readAlong:
        return Icons.menu_book_rounded;
      case ChallengeType.sprint:
        return Icons.bolt_rounded;
      case ChallengeType.genre:
        return Icons.category_rounded;
      case ChallengeType.pages:
        return Icons.auto_stories_rounded;
    }
  }

  void _showInviteFriends(BuildContext context, Challenge challenge) {
    final l10n = AppLocalizations.of(context)!;
    final inboxService = getIt<InboxService>();
    final friendshipService = getIt<FriendshipService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<FriendWithProfile>>(
          future: friendshipService.getAcceptedFriends(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            final friends = snapshot.data!;
            if (friends.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    l10n.noFriendsYet,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 15),
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.selectFriendsToInvite,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ...friends.map((fwp) {
                  final p = fwp.profile;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        p.displayName.isNotEmpty
                            ? p.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(
                      p.displayName,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 15),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await inboxService.sendChallengeInvite(
                          toUserId: p.uid,
                          challengeId: challenge.id,
                          challengeTitle: challenge.title,
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(l10n.inviteSent),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(l10n.inviteFriends),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    AppLocalizations l10n,
    bool isParticipating,
    bool isFull,
    bool isLoading,
  ) {
    if (isParticipating) {
      return OutlinedButton(
        onPressed: isLoading
            ? null
            : () {
                Haptics.warning();
                context.read<ChallengeDetailCubit>().leaveChallenge();
              },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEF4444)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFEF4444),
                ),
              )
            : Text(
                l10n.leaveChallenge,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
      );
    }

    if (isFull) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          l10n.challengeFull,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              Haptics.success();
              context.read<ChallengeDetailCubit>().joinChallenge(l10n);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              l10n.joinChallenge,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
