import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity_entry.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class StreakDetailScreen extends StatefulWidget {
  const StreakDetailScreen({super.key});

  @override
  State<StreakDetailScreen> createState() => _StreakDetailScreenState();
}

class _StreakDetailScreenState extends State<StreakDetailScreen> {
  List<ActivityEntry> _allEntries = [];
  UserProfile? _profile;
  int _pagesReadToday = 0;
  List<ActivityEntry> _todaySessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      getIt<ActivityService>().getRecentEntries(limit: 200),
      getIt<UserProfileService>().getProfile(),
    ]);
    if (mounted) {
      final profile = results[1] as UserProfile?;
      final entries = results[0] as List<ActivityEntry>;

      // Check if pagesReadTodayDate matches today
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final pagesReadToday = profile?.pagesReadTodayDate == todayStr
          ? (profile?.pagesReadToday ?? 0)
          : 0;

      // Filter today's sessions
      final today = DateTime(now.year, now.month, now.day);
      final todaySessions = entries.where((e) {
        final d = DateTime(
            e.timestamp.year, e.timestamp.month, e.timestamp.day);
        return d == today;
      }).toList();

      setState(() {
        _allEntries = entries;
        _profile = profile;
        _pagesReadToday = pagesReadToday;
        _todaySessions = todaySessions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          l10n.streakDetailTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading || _profile == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildStreakHero(l10n, _profile!.streakDays),
                  const SizedBox(height: 24),
                  _buildTodayCard(l10n, _pagesReadToday,
                      _profile!.dailyGoalPages, _profile!.streakDays),
                  const SizedBox(height: 24),
                  // Today's reading sessions
                  if (_todaySessions.isNotEmpty)
                    _buildTodaySessions(l10n),
                  if (_todaySessions.isNotEmpty)
                    const SizedBox(height: 24),
                  _buildStreakRules(l10n),
                  const SizedBox(height: 24),
                  _buildCalendarSection(l10n),
                  const SizedBox(height: 24),
                  _buildDailyBreakdown(l10n),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakHero(AppLocalizations l10n, int streakDays) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.amber.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const AnimatedEmoji(AnimatedEmojis.fire, size: 56),
          const SizedBox(height: 12),
          Text(
            '$streakDays',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: AppColors.amber,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.streakDaysLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (streakDays >= 7) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.streakBonusActive,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amber,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayCard(
      AppLocalizations l10n, int pagesReadToday, int dailyGoal, int streak) {
    final goalReached = pagesReadToday >= dailyGoal;
    final progress =
        dailyGoal > 0 ? (pagesReadToday / dailyGoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goalReached
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.textMuted.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                goalReached
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: goalReached ? AppColors.success : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.streakTodayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (goalReached)
                const AnimatedEmoji(AnimatedEmojis.checkMark, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.backgroundDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                goalReached ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pagesProgress(pagesReadToday, dailyGoal),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (!goalReached) ...[
            const SizedBox(height: 8),
            Text(
              l10n.streakPagesRemaining(dailyGoal - pagesReadToday),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.amber.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodaySessions(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.streakTodaySessions,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ..._todaySessions.map((entry) {
            final time =
                '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
            final pages = entry.pagesRead ?? 0;
            final minutes = entry.durationMinutes ?? 0;

            IconData icon;
            String label;
            switch (entry.type) {
              case ActivityType.focusSession:
                icon = Icons.timer_rounded;
                label = minutes > 0 && pages > 0
                    ? l10n.streakSessionDetail(minutes, pages)
                    : minutes > 0
                        ? l10n.streakDayMinutes(minutes)
                        : l10n.streakDayPages(pages);
              case ActivityType.pageProgress:
                icon = Icons.menu_book_rounded;
                label = l10n.streakDayPages(pages);
              case ActivityType.bookFinished:
                icon = Icons.emoji_events_rounded;
                label = entry.bookTitle ?? l10n.streakDayPages(pages);
              case ActivityType.badgeEarned:
                icon = Icons.military_tech_rounded;
                label = entry.badgeId ?? '';
              case ActivityType.streakMilestone:
                icon = Icons.local_fire_department_rounded;
                label = '${entry.streakDays} ${l10n.streakDaysLabel}';
              default:
                icon = Icons.auto_awesome_rounded;
                label = '+${entry.xpEarned} XP';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (entry.bookTitle != null &&
                            entry.type != ActivityType.bookFinished)
                          Text(
                            entry.bookTitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStreakRules(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.streakHowItWorks,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ruleItem(l10n.streakRule1),
          const SizedBox(height: 10),
          _ruleItem(l10n.streakRule2),
          const SizedBox(height: 10),
          _ruleItem(l10n.streakRule3),
        ],
      ),
    );
  }

  Widget _ruleItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build a set of dates that have activity
    final activeDates = <DateTime>{};
    for (final entry in _allEntries) {
      final d = DateTime(
          entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      activeDates.add(d);
    }

    // Last 28 days
    final days =
        List.generate(28, (i) => today.subtract(Duration(days: 27 - i)));

    // Group pages by date
    final pagesByDate = <DateTime, int>{};
    for (final entry in _allEntries) {
      if (entry.pagesRead != null && entry.pagesRead! > 0) {
        final d = DateTime(
            entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
        pagesByDate[d] = (pagesByDate[d] ?? 0) + entry.pagesRead!;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.streakLast28Days,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <String>[
              l10n.weekdayMon,
              l10n.weekdayTue,
              l10n.weekdayWed,
              l10n.weekdayThu,
              l10n.weekdayFri,
              l10n.weekdaySat,
              l10n.weekdaySun,
            ]
                .map((d) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          _buildCalendarGrid(days, activeDates, pagesByDate, today),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> days, Set<DateTime> activeDates,
      Map<DateTime, int> pagesByDate, DateTime today) {
    final firstDay = days.first;
    final startPad = (firstDay.weekday - 1) % 7;

    final cells = <Widget>[];
    for (var i = 0; i < startPad; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }

    for (final day in days) {
      final isActive = activeDates.contains(day);
      final isToday = day == today;
      final pages = pagesByDate[day] ?? 0;

      cells.add(
        Tooltip(
          message: pages > 0 ? '$pages pages' : '',
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? _getHeatColor(pages)
                  : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: AppColors.amber, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: (MediaQuery.of(context).size.width - 40 - 36 * 7) / 6,
      runSpacing: 6,
      children: cells,
    );
  }

  Color _getHeatColor(int pages) {
    if (pages >= 30) return AppColors.success.withValues(alpha: 0.5);
    if (pages >= 15) return AppColors.success.withValues(alpha: 0.35);
    if (pages >= 5) return AppColors.primary.withValues(alpha: 0.3);
    if (pages >= 1) return AppColors.primary.withValues(alpha: 0.15);
    return AppColors.backgroundDark;
  }

  Widget _buildDailyBreakdown(AppLocalizations l10n) {
    final grouped = <DateTime, List<ActivityEntry>>{};
    for (final entry in _allEntries) {
      final d = DateTime(
          entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      grouped.putIfAbsent(d, () => []).add(entry);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final displayDates = sortedDates.take(14).toList();

    if (displayDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            l10n.streakNoHistory,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.streakRecentActivity,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...displayDates
              .map((date) => _buildDayRow(l10n, date, grouped[date]!)),
        ],
      ),
    );
  }

  Widget _buildDayRow(
      AppLocalizations l10n, DateTime date, List<ActivityEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateLabel;
    if (date == today) {
      dateLabel = l10n.streakToday;
    } else if (date == yesterday) {
      dateLabel = l10n.streakYesterday;
    } else {
      dateLabel =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    }

    int totalPages = 0;
    int totalMinutes = 0;
    int totalXp = 0;
    for (final e in entries) {
      totalPages += e.pagesRead ?? 0;
      totalMinutes += e.durationMinutes ?? 0;
      totalXp += e.xpEarned;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: totalPages > 0 ? AppColors.success : AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (totalPages > 0)
                  Text(
                    l10n.streakDayPages(totalPages),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (totalMinutes > 0)
                  Text(
                    l10n.streakDayMinutes(totalMinutes),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (totalXp > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$totalXp XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
