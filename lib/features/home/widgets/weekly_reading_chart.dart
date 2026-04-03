import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity_entry.dart';

/// Bar chart showing daily reading minutes for the last 7 days.
/// Data is derived from activity entries (focusSession type).
class WeeklyReadingChart extends StatelessWidget {
  final List<ActivityEntry> entries;

  const WeeklyReadingChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final dailyData = _buildDailyData();
    final maxMinutes = dailyData
        .map((d) => d.minutes)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxMinutes < 10 ? 30.0 : (maxMinutes * 1.3).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total this week summary
          Row(
            children: [
              _StatPill(
                icon: Icons.timer_rounded,
                value: '${dailyData.fold<int>(0, (s, d) => s + d.minutes.round())}',
                unit: 'dk',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.auto_stories_rounded,
                value: '${_totalPages()}',
                unit: 'sayfa',
                color: const Color(0xFF22C55E),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()} dk',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dailyData.length) {
                          return const SizedBox.shrink();
                        }
                        final d = dailyData[index];
                        final isToday = index == dailyData.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            d.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dailyData.length, (i) {
                  final d = dailyData[i];
                  final isToday = i == dailyData.length - 1;
                  final hasData = d.minutes > 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: hasData ? d.minutes : 2, // min bar for empty days
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        gradient: hasData
                            ? LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isToday
                                    ? [
                                        AppColors.primary,
                                        AppColors.primaryLight,
                                      ]
                                    : [
                                        AppColors.primary
                                            .withValues(alpha: 0.5),
                                        AppColors.primary
                                            .withValues(alpha: 0.3),
                                      ],
                              )
                            : null,
                        color: hasData
                            ? null
                            : AppColors.textMuted.withValues(alpha: 0.1),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  List<_DayData> _buildDailyData() {
    final now = DateTime.now();
    final days = <_DayData>[];
    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayLabel = i == 0 ? 'Bugün' : dayNames[date.weekday - 1];

      double minutes = 0;
      for (final entry in entries) {
        if (entry.type == ActivityType.focusSession) {
          final entryDate = DateTime(
            entry.timestamp.year,
            entry.timestamp.month,
            entry.timestamp.day,
          );
          if (entryDate == date) {
            minutes += (entry.durationMinutes ?? 0).toDouble();
          }
        }
      }

      days.add(_DayData(label: dayLabel, minutes: minutes));
    }

    return days;
  }

  int _totalPages() {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: 6));
    int pages = 0;
    for (final entry in entries) {
      if (entry.timestamp.isAfter(weekStart)) {
        pages += entry.pagesRead ?? 0;
      }
    }
    return pages;
  }
}

class _DayData {
  final String label;
  final double minutes;

  const _DayData({required this.label, required this.minutes});
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$value $unit',
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
