import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/reader_profile_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../screens/edit_profile_screen.dart';
import '../widgets/badge_preview_row.dart';
import '../../reader_profile/widgets/reader_profile_card.dart';

/// Profile tab — cubit is provided by ShellScreen, not created here.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading ||
                state.status == ProfileStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state.status == ProfileStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Something went wrong',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          context.read<ProfileCubit>().loadProfile(),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            }

            final profile = state.profile!;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Header title
                  Text(
                    l10n.profile,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile header - avatar + name + email + edit button
                  Row(
                    children: [
                      Expanded(child: _buildProfileHeader(profile)),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(
                                currentDisplayName: profile.displayName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  // Version info (below FCM token)
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final info = snapshot.data!;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'v${info.version} (${info.buildNumber})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Daily reading goal (right below name)
                  _buildDailyGoalButton(context, profile),
                  const SizedBox(height: 20),

                  // Reader Profile card
                  FutureBuilder(
                    future: getIt<ReaderProfileRepository>().getReaderProfile(),
                    builder: (context, snapshot) {
                      final readerProfile = snapshot.data;
                      return ReaderProfileCard(
                        profile: readerProfile,
                        onTap: () {
                          if (readerProfile != null) {
                            context.push('/reader-profile-detail');
                          } else {
                            context.push('/reader-profile-quiz');
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Badge preview row (hidden in calm mode)
                  if (!profile.calmMode) ...[
                    BadgePreviewRow(earnedBadges: state.earnedBadges),
                    const SizedBox(height: 20),
                  ],

                  // Stats grid
                  _buildStatsGrid(profile),
                  const SizedBox(height: 20),

                  // Enable notifications
                  _buildNotificationButton(context),
                  const SizedBox(height: 12),

                  // Calm Mode toggle
                  _buildCalmModeToggle(context, profile),
                  const SizedBox(height: 12),

                  // How It Works guide button
                  GameButton(
                    onTap: () => context.push('/how-it-works'),
                    color: AppColors.surfaceDark,
                    shadowColor: AppColors.primary.withValues(alpha: 0.2),
                    shadowHeight: 4,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 20, color: AppColors.textPrimary),
                        const SizedBox(width: 10),
                        Text(
                          l10n.howItWorks,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sign Out
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSignOutDialog(context, l10n),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text(
                        l10n.signOut,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Delete Account
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton.icon(
                      onPressed: () => _showDeleteDialog(context, l10n),
                      icon:
                          const Icon(Icons.delete_outline_rounded, size: 20),
                      label: Text(
                        l10n.deleteAccount,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(profile) {
    final initials = profile.displayName.isNotEmpty
        ? profile.displayName
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return Row(
      children: [
        // Avatar
        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
          CircleAvatar(
            radius: 36,
            backgroundImage: NetworkImage(profile.avatarUrl!),
            backgroundColor: AppColors.surfaceDark,
          )
        else
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  profile.subscriptionTier.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FutureBuilder<String?>(
                future: FirebaseMessaging.instance.getToken(),
                builder: (context, snapshot) {
                  final token = snapshot.data;
                  if (token == null) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: token));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('FCM Token copied!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            token,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalmModeToggle(BuildContext context, profile) {
    final l10n = AppLocalizations.of(context)!;
    final isCalmMode = profile.calmMode as bool;

    return GameButton(
      onTap: () {
        if (isCalmMode) {
          _showDisableCalmModeDialog(context, l10n);
        } else {
          _showCalmModeDialog(context, l10n);
        }
      },
      color: isCalmMode
          ? const Color(0xFF1B3A2D)
          : AppColors.surfaceDark,
      shadowColor: isCalmMode
          ? const Color(0xFF22C55E).withValues(alpha: 0.2)
          : AppColors.primary.withValues(alpha: 0.2),
      shadowHeight: 4,
      borderRadius: 12,
      border: isCalmMode
          ? Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4))
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.spa_rounded,
            size: 20,
            color: isCalmMode ? const Color(0xFF22C55E) : AppColors.textPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.calmMode,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCalmMode ? const Color(0xFF22C55E) : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.calmModeSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isCalmMode,
            onChanged: (_) {
              if (isCalmMode) {
                _showDisableCalmModeDialog(context, l10n);
              } else {
                _showCalmModeDialog(context, l10n);
              }
            },
            activeColor: const Color(0xFF22C55E),
            activeTrackColor: const Color(0xFF22C55E).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  void _showCalmModeDialog(BuildContext context, AppLocalizations l10n) async {
    final cubit = context.read<ProfileCubit>();
    final challengeCount = await cubit.getActiveChallengeCount();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.spa_rounded, color: Color(0xFF22C55E), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.calmModeConfirmTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.calmModeConfirmMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            if (challengeCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.calmModeConfirmWithChallenges(challengeCount),
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Haptics.light();
              Navigator.pop(ctx);
              cubit.enableCalmMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.calmModeEnabled),
                  backgroundColor: const Color(0xFF22C55E),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              l10n.enable,
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisableCalmModeDialog(BuildContext context, AppLocalizations l10n) {
    final cubit = context.read<ProfileCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.spa_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.calmModeDisableTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.calmModeDisableMessage,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Haptics.light();
              Navigator.pop(ctx);
              cubit.disableCalmMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.calmModeDisabled),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              l10n.confirm,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(profile) {
    final isCalmMode = profile.calmMode as bool;

    final stats = isCalmMode
        ? [
            _StatItem(Icons.menu_book_rounded, AppColors.primary, '${profile.booksRead}', 'Books Read'),
            _StatItem(Icons.auto_stories_rounded, AppColors.primaryLight, '${profile.pagesRead}', 'Pages Read'),
            _StatItem(Icons.timer_rounded, Colors.tealAccent, '${profile.focusMinutesTotal}', 'Focus Min'),
          ]
        : [
            _StatItem(Icons.star_rounded, AppColors.amber, '${profile.xpTotal}', 'Total XP'),
            _StatItem(Icons.local_fire_department_rounded, Colors.orangeAccent, '${profile.streakDays}', 'Day Streak'),
            _StatItem(Icons.menu_book_rounded, AppColors.primary, '${profile.booksRead}', 'Books Read'),
            _StatItem(Icons.auto_stories_rounded, AppColors.primaryLight, '${profile.pagesRead}', 'Pages Read'),
            _StatItem(Icons.timer_rounded, Colors.tealAccent, '${profile.focusMinutesTotal}', 'Focus Min'),
            _StatItem(Icons.emoji_events_rounded, AppColors.amber, _formatLeague(profile.currentLeague), 'League'),
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: stat.color.withValues(alpha: 0.6),
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(stat.icon, size: 24, color: stat.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatLeague(String league) {
    if (league.isEmpty) return 'Bronze';
    return league[0].toUpperCase() + league.substring(1);
  }

  Widget _buildDailyGoalButton(BuildContext context, profile) {
    final l10n = AppLocalizations.of(context)!;
    return GameButton(
      onTap: () async {
          final result = await context.push<int>('/daily-goal', extra: profile.dailyGoalPages);
          if (result != null && context.mounted) {
            context.read<ProfileCubit>().updateDailyGoal(result);
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.dailyGoalUpdated),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      color: AppColors.surfaceDark,
      shadowColor: AppColors.amber.withValues(alpha: 0.2),
      shadowHeight: 4,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.track_changes_rounded, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.dailyGoal,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            l10n.pagesPerDayCount(profile.dailyGoalPages),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GameButton(
      onTap: () => context.push('/notification-settings'),
      color: AppColors.surfaceDark,
      shadowColor: AppColors.primary.withValues(alpha: 0.2),
      shadowHeight: 4,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Text(
            l10n.notificationSettings,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dialog methods (copied from profile_placeholder_tab.dart) ───

  void _showSignOutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.signOutConfirmTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.signOutConfirmMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Haptics.warning();
              Navigator.pop(ctx);
              await getIt<AuthService>().signOut();
            },
            child: Text(
              l10n.signOut,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.deleteAccountConfirmTitle,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.deleteAccountConfirmMessage,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Haptics.warning();
              Navigator.pop(ctx);
              await _performAccountDeletion(context, l10n);
            },
            child: Text(
              l10n.deleteAccountButton,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final authService = getIt<AuthService>();
    final profileService = getIt<UserProfileService>();
    final user = authService.currentUser;
    if (user == null) return;

    final providerIds = user.providerData.map((p) => p.providerId).toList();
    final isEmailUser = providerIds.contains('password');

    try {
      // Email users need password re-auth via dialog
      if (isEmailUser) {
        final password = await _showPasswordDialog(context, l10n);
        if (password == null) return; // cancelled

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        // Google/Apple re-auth
        await authService.reauthenticate();
      }

      // Now delete data then account
      await profileService.deleteUserData();
      await authService.deleteAccount();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.reauthRequired,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.enterPassword,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final password = controller.text.trim();
              if (password.isNotEmpty) {
                Navigator.pop(ctx, password);
              }
            },
            child: Text(
              l10n.confirm,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatItem(this.icon, this.color, this.value, this.label);
}
