import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/inbox_notification.dart';
import '../../../core/services/service_locator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/inbox_cubit.dart';
import '../cubit/inbox_state.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InboxCubit>()..loadNotifications(),
      child: const _InboxScreenContent(),
    );
  }
}

class _InboxScreenContent extends StatelessWidget {
  const _InboxScreenContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inbox),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: BlocListener<InboxCubit, InboxState>(
        listenWhen: (prev, curr) =>
            curr.status == InboxStatus.error && curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? '',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        },
        child: BlocBuilder<InboxCubit, InboxState>(
        builder: (context, state) {
          if (state.status == InboxStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedEmoji(AnimatedEmojis.sleep, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noNotifications,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          // Group notifications by date
          final grouped = _groupByDate(context, state.notifications);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                context.read<InboxCubit>().loadNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                return _DateGroup(
                  dateLabel: group.label,
                  notifications: group.notifications,
                );
              },
            ),
          );
        },
      ),
      ),
    );
  }

  List<_NotificationGroup> _groupByDate(
      BuildContext context, List<InboxNotification> notifications) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<InboxNotification>> map = {};
    final Map<String, int> order = {};
    int orderIdx = 0;

    for (final n in notifications) {
      final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String label;
      if (date == today) {
        label = l10n.today;
      } else if (date == yesterday) {
        label = l10n.yesterday;
      } else {
        label =
            '${n.createdAt.day.toString().padLeft(2, '0')}.${n.createdAt.month.toString().padLeft(2, '0')}.${n.createdAt.year}';
      }

      map.putIfAbsent(label, () => []).add(n);
      order.putIfAbsent(label, () => orderIdx++);
    }

    final groups = map.entries
        .map((e) => _NotificationGroup(label: e.key, notifications: e.value))
        .toList();
    groups.sort((a, b) => order[a.label]!.compareTo(order[b.label]!));
    return groups;
  }
}

class _NotificationGroup {
  final String label;
  final List<InboxNotification> notifications;

  _NotificationGroup({required this.label, required this.notifications});
}

class _DateGroup extends StatelessWidget {
  final String dateLabel;
  final List<InboxNotification> notifications;

  const _DateGroup({
    required this.dateLabel,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
        // Notification items with timeline line
        ...List.generate(notifications.length, (index) {
          final notification = notifications[index];
          final isLast = index == notifications.length - 1;
          return _TimelineNotificationItem(
            notification: notification,
            isLast: isLast,
          );
        }),
      ],
    );
  }
}

class _TimelineNotificationItem extends StatelessWidget {
  final InboxNotification notification;
  final bool isLast;

  const _TimelineNotificationItem({
    required this.notification,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<InboxCubit>();
    final timeStr =
        '${notification.createdAt.hour.toString().padLeft(2, '0')}:${notification.createdAt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      onDismissed: (_) => cubit.deleteNotification(notification.id),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline line
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: notification.read
                          ? AppColors.textMuted
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                ],
              ),
            ),
            // Content card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCard(context, l10n, timeStr, cubit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppLocalizations l10n,
    String timeStr,
    InboxCubit cubit,
  ) {
    if (notification.type == InboxNotificationType.pushNotification) {
      return _PushNotificationCard(
        notification: notification,
        timeStr: timeStr,
        onTap: () {
          if (!notification.read) {
            cubit.markAsRead(notification.id);
          }
        },
      );
    } else {
      return _ChallengeInviteCard(
        notification: notification,
        timeStr: timeStr,
        l10n: l10n,
        cubit: cubit,
      );
    }
  }
}

class _PushNotificationCard extends StatelessWidget {
  final InboxNotification notification;
  final String timeStr;
  final VoidCallback onTap;

  const _PushNotificationCard({
    required this.notification,
    required this.timeStr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.read
              ? AppColors.surfaceDark
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: notification.read
              ? null
              : Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: AppColors.primary,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notification.title ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          notification.read ? FontWeight.w500 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            if (notification.body != null &&
                notification.body!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Text(
                  notification.body!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChallengeInviteCard extends StatelessWidget {
  final InboxNotification notification;
  final String timeStr;
  final AppLocalizations l10n;
  final InboxCubit cubit;

  const _ChallengeInviteCard({
    required this.notification,
    required this.timeStr,
    required this.l10n,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: notification.read
            ? null
            : Border.all(
                color: AppColors.amber.withValues(alpha: 0.2),
                width: 1,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.amber,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification.challengeTitle ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              l10n.challengeInviteFrom(notification.fromUserName ?? ''),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: _buildActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (notification.actionTaken == 'accepted') {
      return Text(
        l10n.accepted,
        style: const TextStyle(
          color: Color(0xFF4ADE80),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (notification.actionTaken == 'rejected') {
      return Text(
        l10n.declined,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Row(
      children: [
        _ActionChip(
          label: l10n.accept,
          color: const Color(0xFF4ADE80),
          onTap: () => cubit.acceptInvite(
            notification.id,
            notification.challengeId ?? '',
          ),
        ),
        const SizedBox(width: 8),
        _ActionChip(
          label: l10n.decline,
          color: AppColors.textMuted,
          onTap: () => cubit.rejectInvite(notification.id),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
