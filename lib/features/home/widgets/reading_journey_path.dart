import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/badge_definitions.dart';
import '../../../core/models/activity_entry.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'weekly_reading_chart.dart';

/// Reading-focused journey timeline with optional weekly chart.
class ReadingJourneyPath extends StatefulWidget {
  final List<ActivityEntry> entries;
  final VoidCallback? onContinue;
  final void Function(String entryId)? onDeleteEntry;

  const ReadingJourneyPath({
    super.key,
    required this.entries,
    this.onContinue,
    this.onDeleteEntry,
  });

  @override
  State<ReadingJourneyPath> createState() => _ReadingJourneyPathState();
}

class _ReadingJourneyPathState extends State<ReadingJourneyPath> {
  bool _showChart = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.entries.isEmpty) {
      return _emptyState(l10n);
    }

    final rows = _buildRows(widget.entries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header: chart toggle + title + continue button
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showChart = !_showChart),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _showChart
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: _showChart ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.readingJourney,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            _ContinueButton(onTap: widget.onContinue, label: l10n.journeyContinue),
          ],
        ),
        const SizedBox(height: 12),

        // Weekly chart (togglable)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: WeeklyReadingChart(entries: widget.entries),
          ),
          crossFadeState: _showChart
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),

        // Timeline
        ...List.generate(rows.length, (i) {
          final row = rows[i];
          return _TimelineRow(
            row: row,
            isFirst: i == 0,
            isLast: i == rows.length - 1,
            onDelete: widget.onDeleteEntry,
          );
        }),
      ],
    );
  }

  Widget _emptyState(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_stories_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            l10n.journeyEmptyTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.journeyEmptySubtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _ContinueButton(onTap: widget.onContinue, label: l10n.journeyContinue),
        ],
      ),
    );
  }

  /// Merges entries into display rows.
  ///
  /// Reading entries (focusSession, pageProgress, bookFinished) become
  /// primary rows. Non-reading entries (badgeEarned, streakMilestone,
  /// challengeCompleted, levelUp) are attached to the preceding reading
  /// row as inline chips. If no reading row precedes them they become
  /// standalone rows.
  List<_JourneyRow> _buildRows(List<ActivityEntry> entries) {
    final rows = <_JourneyRow>[];

    for (final entry in entries) {
      if (_isReadingEntry(entry)) {
        rows.add(_JourneyRow(entry: entry, attachments: []));
      } else {
        // Attach to last reading row if close in time (within 60s)
        if (rows.isNotEmpty) {
          final lastRow = rows.last;
          final diff = lastRow.entry.timestamp.difference(entry.timestamp).abs();
          if (diff.inSeconds < 60) {
            lastRow.attachments.add(entry);
            continue;
          }
        }
        // Otherwise standalone
        rows.add(_JourneyRow(entry: entry, attachments: []));
      }
    }

    return rows;
  }

  bool _isReadingEntry(ActivityEntry e) {
    return e.type == ActivityType.focusSession ||
        e.type == ActivityType.pageProgress ||
        e.type == ActivityType.bookFinished;
  }
}

/// A display row in the journey timeline.
class _JourneyRow {
  final ActivityEntry entry;
  final List<ActivityEntry> attachments;

  _JourneyRow({required this.entry, required this.attachments});
}

/// A single timeline row with left timeline indicator + content card.
class _TimelineRow extends StatelessWidget {
  final _JourneyRow row;
  final bool isFirst;
  final bool isLast;
  final void Function(String entryId)? onDelete;

  const _TimelineRow({
    required this.row,
    required this.isFirst,
    required this.isLast,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReading = _isReadingType(row.entry.type);
    final config = _entryConfig(row.entry.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                Container(
                  width: isFirst ? 14 : 10,
                  height: isFirst ? 14 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? config.color : config.color.withValues(alpha: 0.6),
                    boxShadow: isFirst
                        ? [
                            BoxShadow(
                              color: config.color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                // Vertical line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppColors.textMuted.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onLongPress: () => _showDeleteDialog(context, l10n),
                child: isReading
                    ? _buildReadingCard(context, l10n, config)
                    : _buildMilestoneChip(context, l10n, config),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card for reading entries (focus session, page progress, book finished).
  Widget _buildReadingCard(
    BuildContext context,
    AppLocalizations l10n,
    _EntryConfig config,
  ) {
    final entry = row.entry;
    final bookTitle = entry.bookTitle ?? l10n.journeyFocusSession;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: isFirst
            ? Border.all(color: config.color.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + XP
          Row(
            children: [
              Text(
                _formatDate(entry.timestamp, l10n),
                style: TextStyle(
                  fontSize: 11,
                  color: isFirst ? config.color.withValues(alpha: 0.8) : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (entry.xpEarned > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${entry.xpEarned} XP',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Book title row with icon
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(config.icon, color: config.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _readingDetail(entry, l10n),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Attached badges / milestones as inline chips
          if (row.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: row.attachments.map((a) {
                return _AttachmentChip(entry: a);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Compact chip for standalone non-reading entries.
  Widget _buildMilestoneChip(
    BuildContext context,
    AppLocalizations l10n,
    _EntryConfig config,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: config.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: config.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(config.icon, color: config.color, size: 14),
              const SizedBox(width: 6),
              Text(
                _milestoneLabel(row.entry, l10n),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: config.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDate(row.entry.timestamp, l10n),
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, AppLocalizations l10n) {
    final entryId = row.entry.id;
    if (entryId.isEmpty || onDelete == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteActivity,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.deleteActivityConfirm,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete!(entryId);
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _readingDetail(ActivityEntry entry, AppLocalizations l10n) {
    switch (entry.type) {
      case ActivityType.focusSession:
        final mins = entry.durationMinutes ?? 0;
        final pages = entry.pagesRead ?? 0;
        if (pages > 0 && mins > 0) {
          return '$pages ${l10n.pages} · $mins ${l10n.journeyMin}';
        } else if (pages > 0) {
          return '$pages ${l10n.pages}';
        } else {
          return l10n.journeyFocusMinutes(mins);
        }
      case ActivityType.pageProgress:
        return '${entry.pagesRead ?? 0} ${l10n.pages}';
      case ActivityType.bookFinished:
        return l10n.journeyBookFinished;
      default:
        return '';
    }
  }

  String _milestoneLabel(ActivityEntry entry, AppLocalizations l10n) {
    switch (entry.type) {
      case ActivityType.badgeEarned:
        return _badgeName(l10n, entry.badgeId);
      case ActivityType.streakMilestone:
        return l10n.dayStreak(entry.streakDays ?? 0);
      case ActivityType.challengeCompleted:
        return entry.challengeTitle ?? l10n.journeyChallengeCompleted;
      case ActivityType.levelUp:
        return 'Lv ${entry.newLevel ?? 0}';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(entryDay).inDays;

    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diff == 0) return '${l10n.journeyToday}, $time';
    if (diff == 1) return '${l10n.journeyYesterday}, $time';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} · $time';
  }

  String _badgeName(AppLocalizations l10n, String? badgeId) {
    if (badgeId == null) return '';
    try {
      final def = allBadges.firstWhere((b) => b.id == badgeId);
      return _resolveL10nKey(l10n, def.nameKey);
    } catch (_) {
      return badgeId;
    }
  }

  String _resolveL10nKey(AppLocalizations l10n, String key) {
    switch (key) {
      case 'badgeFirstPage': return l10n.badgeFirstPage;
      case 'badgeFiftyPages': return l10n.badgeFiftyPages;
      case 'badgeTwoHundredPages': return l10n.badgeTwoHundredPages;
      case 'badgeFiveHundredPages': return l10n.badgeFiveHundredPages;
      case 'badgePageTurner': return l10n.badgePageTurner;
      case 'badgeMarathonReader': return l10n.badgeMarathonReader;
      case 'badgeFirstBook': return l10n.badgeFirstBook;
      case 'badgeThreeBooks': return l10n.badgeThreeBooks;
      case 'badgeBookworm': return l10n.badgeBookworm;
      case 'badgeCenturyClub': return l10n.badgeCenturyClub;
      case 'badgeGettingStarted': return l10n.badgeGettingStarted;
      case 'badgeThreeDayStreak': return l10n.badgeThreeDayStreak;
      case 'badgeFiveDayStreak': return l10n.badgeFiveDayStreak;
      case 'badgeOnFire': return l10n.badgeOnFire;
      case 'badgeTwoWeekStreak': return l10n.badgeTwoWeekStreak;
      case 'badgeUnstoppable': return l10n.badgeUnstoppable;
      case 'badgeLegend': return l10n.badgeLegend;
      case 'badgeImmortal': return l10n.badgeImmortal;
      case 'badgeFirstFocus': return l10n.badgeFirstFocus;
      case 'badgeFocusFive': return l10n.badgeFocusFive;
      case 'badgeFocusRegular': return l10n.badgeFocusRegular;
      case 'badgeFocusMaster': return l10n.badgeFocusMaster;
      case 'badgeFocusHour': return l10n.badgeFocusHour;
      case 'badgeFocusTenHours': return l10n.badgeFocusTenHours;
      default: return key;
    }
  }

  bool _isReadingType(ActivityType type) {
    return type == ActivityType.focusSession ||
        type == ActivityType.pageProgress ||
        type == ActivityType.bookFinished;
  }

  _EntryConfig _entryConfig(ActivityType type) {
    switch (type) {
      case ActivityType.focusSession:
        return _EntryConfig(Icons.timer_rounded, const Color(0xFF6467F2));
      case ActivityType.pageProgress:
        return _EntryConfig(Icons.auto_stories_rounded, const Color(0xFF22C55E));
      case ActivityType.bookFinished:
        return _EntryConfig(Icons.emoji_events_rounded, const Color(0xFFF59E0B));
      case ActivityType.badgeEarned:
        return _EntryConfig(Icons.military_tech_rounded, const Color(0xFFEC4899));
      case ActivityType.streakMilestone:
        return _EntryConfig(Icons.local_fire_department_rounded, const Color(0xFFEF4444));
      case ActivityType.challengeCompleted:
        return _EntryConfig(Icons.flag_rounded, const Color(0xFF8B5CF6));
      case ActivityType.levelUp:
        return _EntryConfig(Icons.trending_up_rounded, const Color(0xFF06B6D4));
    }
  }
}

/// Small inline chip for badges/milestones attached to a reading row.
class _AttachmentChip extends StatelessWidget {
  final ActivityEntry entry;

  const _AttachmentChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = _chipConfig(entry.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: 4),
          Text(
            _label(l10n),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n) {
    switch (entry.type) {
      case ActivityType.badgeEarned:
        return _badgeName(l10n, entry.badgeId);
      case ActivityType.streakMilestone:
        return l10n.dayStreak(entry.streakDays ?? 0);
      case ActivityType.challengeCompleted:
        return entry.challengeTitle ?? l10n.journeyChallengeCompleted;
      case ActivityType.levelUp:
        return 'Lv ${entry.newLevel ?? 0}';
      default:
        return '';
    }
  }

  String _badgeName(AppLocalizations l10n, String? badgeId) {
    if (badgeId == null) return '';
    try {
      final def = allBadges.firstWhere((b) => b.id == badgeId);
      return _resolveL10nKey(l10n, def.nameKey);
    } catch (_) {
      return badgeId;
    }
  }

  String _resolveL10nKey(AppLocalizations l10n, String key) {
    switch (key) {
      case 'badgeFirstPage': return l10n.badgeFirstPage;
      case 'badgeFiftyPages': return l10n.badgeFiftyPages;
      case 'badgeTwoHundredPages': return l10n.badgeTwoHundredPages;
      case 'badgeFiveHundredPages': return l10n.badgeFiveHundredPages;
      case 'badgePageTurner': return l10n.badgePageTurner;
      case 'badgeMarathonReader': return l10n.badgeMarathonReader;
      case 'badgeFirstBook': return l10n.badgeFirstBook;
      case 'badgeThreeBooks': return l10n.badgeThreeBooks;
      case 'badgeBookworm': return l10n.badgeBookworm;
      case 'badgeCenturyClub': return l10n.badgeCenturyClub;
      case 'badgeGettingStarted': return l10n.badgeGettingStarted;
      case 'badgeThreeDayStreak': return l10n.badgeThreeDayStreak;
      case 'badgeFiveDayStreak': return l10n.badgeFiveDayStreak;
      case 'badgeOnFire': return l10n.badgeOnFire;
      case 'badgeTwoWeekStreak': return l10n.badgeTwoWeekStreak;
      case 'badgeUnstoppable': return l10n.badgeUnstoppable;
      case 'badgeLegend': return l10n.badgeLegend;
      case 'badgeImmortal': return l10n.badgeImmortal;
      case 'badgeFirstFocus': return l10n.badgeFirstFocus;
      case 'badgeFocusFive': return l10n.badgeFocusFive;
      case 'badgeFocusRegular': return l10n.badgeFocusRegular;
      case 'badgeFocusMaster': return l10n.badgeFocusMaster;
      case 'badgeFocusHour': return l10n.badgeFocusHour;
      case 'badgeFocusTenHours': return l10n.badgeFocusTenHours;
      default: return key;
    }
  }

  _EntryConfig _chipConfig(ActivityType type) {
    switch (type) {
      case ActivityType.badgeEarned:
        return _EntryConfig(Icons.military_tech_rounded, const Color(0xFFEC4899));
      case ActivityType.streakMilestone:
        return _EntryConfig(Icons.local_fire_department_rounded, const Color(0xFFEF4444));
      case ActivityType.challengeCompleted:
        return _EntryConfig(Icons.flag_rounded, const Color(0xFF8B5CF6));
      case ActivityType.levelUp:
        return _EntryConfig(Icons.trending_up_rounded, const Color(0xFF06B6D4));
      default:
        return _EntryConfig(Icons.star_rounded, AppColors.primary);
    }
  }
}

/// Compact "Continue Journey" pill button for the section header.
class _ContinueButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const _ContinueButton({this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryConfig {
  final IconData icon;
  final Color color;

  const _EntryConfig(this.icon, this.color);
}
