import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/challenge.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/widgets/in_app_notification_banner.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/cubit/home_cubit.dart';
import '../../library/cubit/library_cubit.dart';
import '../../focus/cubit/focus_cubit.dart';
import '../../focus/cubit/book_notes_cubit.dart';
import '../../discover/cubit/discover_cubit.dart';
import '../../profile/cubit/profile_cubit.dart';

/// Shell screen that provides tab cubits at the shell level.
/// Cubits are created once and persist across tab switches,
/// avoiding redundant Firestore reads and loading spinners.
class ShellScreen extends StatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late final HomeCubit _homeCubit;
  late final LibraryCubit _libraryCubit;
  late final FocusCubit _focusCubit;
  late final BookNotesCubit _bookNotesCubit;
  late final DiscoverCubit _discoverCubit;
  late final ProfileCubit _profileCubit;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _homeCubit = getIt<HomeCubit>()..loadHome();
    _libraryCubit = getIt<LibraryCubit>()..loadLibrary();
    _focusCubit = getIt<FocusCubit>()..loadInitialData();
    _bookNotesCubit = getIt<BookNotesCubit>();
    _discoverCubit = getIt<DiscoverCubit>()..loadChallenges();
    _profileCubit = getIt<ProfileCubit>()..loadProfile();

    // Wire up in-app notification banner for foreground FCM messages
    getIt<NotificationService>().onShowBanner = _showBanner;

    // Refresh all notifications with correct locale on every app resume
    _lifecycleListener = AppLifecycleListener(
      onResume: () => _refreshAllNotifications(),
    );

    // Also refresh on initial load (after context/l10n become available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllNotifications();
    });
  }

  void _showBanner(String title, String body) {
    if (!mounted) return;
    InAppNotificationBanner.show(
      context,
      title: title,
      body: body,
      onTap: () => context.push('/inbox'),
    );
    // Refresh home to update badge count
    _homeCubit.refreshHome();
  }

  /// Refreshes all scheduled local notifications with current device locale.
  /// Called on initial load and every app resume to fix stale/wrong-language notifications.
  void _refreshAllNotifications() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final profile = _homeCubit.state.userProfile;

    // 1. Reading reminders — always refresh
    _homeCubit.refreshReadingReminders(
      title: l10n.readingReminderNotifTitle,
      body: l10n.readingReminderNotifBody,
    );

    // 2. Daily goal notification — refresh if profile loaded
    if (profile != null) {
      final remaining = profile.dailyGoalPages - _homeCubit.state.pagesReadToday;
      _homeCubit.scheduleDailyGoalNotification(
        title: l10n.dailyGoalNotifTitle,
        body: l10n.dailyGoalNotifBody(remaining),
      );
    }

    // 3. Challenge notifications — re-schedule with current locale
    _homeCubit.refreshChallengeNotifications(
      lastDayTitle: l10n.challengeLastDayTitle,
      midPointTitle: l10n.challengeMidPointTitle,
      lastDayBodyBuilder: (challenge) {
        switch (challenge.type) {
          case ChallengeType.pages:
          case ChallengeType.readAlong:
            return l10n.challengeLastDayPageBody(
              challenge.title,
              challenge.targetPages ?? 0,
            );
          case ChallengeType.sprint:
            return l10n.challengeLastDaySprintBody(challenge.title);
          case ChallengeType.genre:
            return l10n.challengeLastDayGenreBody(challenge.title);
        }
      },
      midPointBodyBuilder: (challenge) {
        switch (challenge.type) {
          case ChallengeType.pages:
          case ChallengeType.readAlong:
            return l10n.challengeMidPointPageBody(
              challenge.title,
              challenge.targetPages ?? 0,
            );
          case ChallengeType.sprint:
            return l10n.challengeMidPointSprintBody(
              challenge.title,
              challenge.targetMinutes ?? 0,
            );
          case ChallengeType.genre:
            return l10n.challengeMidPointGenreBody(
              challenge.title,
              challenge.targetBooks ?? 0,
            );
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    getIt<NotificationService>().onShowBanner = null;
    _homeCubit.close();
    _libraryCubit.close();
    _focusCubit.close();
    _bookNotesCubit.close();
    _discoverCubit.close();
    _profileCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = _calculateSelectedIndex(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>.value(value: _homeCubit),
        BlocProvider<LibraryCubit>.value(value: _libraryCubit),
        BlocProvider<FocusCubit>.value(value: _focusCubit),
        BlocProvider<BookNotesCubit>.value(value: _bookNotesCubit),
        BlocProvider<DiscoverCubit>.value(value: _discoverCubit),
        BlocProvider<ProfileCubit>.value(value: _profileCubit),
      ],
      child: Scaffold(
        body: widget.child,
        extendBody: true,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: l10n.navHome,
                    isActive: currentIndex == 0,
                    onTap: () => _onItemTapped(0, context),
                  ),
                  _NavItem(
                    icon: Icons.library_books_outlined,
                    activeIcon: Icons.library_books_rounded,
                    label: l10n.navLibrary,
                    isActive: currentIndex == 1,
                    onTap: () => _onItemTapped(1, context),
                  ),
                  // Center Focus button
                  _FocusCenterButton(
                    isActive: currentIndex == 2,
                    onTap: () => _onItemTapped(2, context),
                  ),
                  _NavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: l10n.navDiscover,
                    isActive: currentIndex == 3,
                    onTap: () => _onItemTapped(3, context),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person_rounded,
                    label: l10n.navProfile,
                    isActive: currentIndex == 4,
                    onTap: () => _onItemTapped(4, context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/focus')) return 2;
    if (location.startsWith('/discover')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        _homeCubit.refreshHome();
        context.go('/home');
      case 1:
        _libraryCubit.loadLibrary();
        context.go('/library');
      case 2:
        _focusCubit.loadInitialData();
        context.go('/focus');
      case 3:
        context.go('/discover');
      case 4:
        context.go('/profile');
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusCenterButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _FocusCenterButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C7FF7),
              AppColors.primary,
              Color(0xFF4A4DD0),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isActive ? Icons.timer_rounded : Icons.timer_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
