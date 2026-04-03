import 'package:flutter/material.dart';
import '../../../core/models/challenge.dart';

class ChallengeTemplate {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final ChallengeType type;
  final int durationDays;
  final int? targetPages;
  final int? targetBooks;
  final int? targetMinutes;
  final IconData icon;
  final Color color;
  final String emoji;

  const ChallengeTemplate({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.type,
    required this.durationDays,
    this.targetPages,
    this.targetBooks,
    this.targetMinutes,
    required this.icon,
    required this.color,
    required this.emoji,
  });

  static const List<ChallengeTemplate> templates = [
    ChallengeTemplate(
      id: 'weekend_sprint',
      titleKey: 'templateWeekendSprint',
      descriptionKey: 'templateWeekendSprintDesc',
      type: ChallengeType.pages,
      durationDays: 2,
      targetPages: 100,
      icon: Icons.weekend_rounded,
      color: Color(0xFFF59E0B),
      emoji: '\u26A1',
    ),
    ChallengeTemplate(
      id: 'page_turner_30',
      titleKey: 'templatePageTurner',
      descriptionKey: 'templatePageTurnerDesc',
      type: ChallengeType.pages,
      durationDays: 30,
      targetPages: 1000,
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF8B5CF6),
      emoji: '\uD83D\uDD25',
    ),
    ChallengeTemplate(
      id: 'genre_explorer',
      titleKey: 'templateGenreExplorer',
      descriptionKey: 'templateGenreExplorerDesc',
      type: ChallengeType.genre,
      durationDays: 30,
      targetBooks: 3,
      icon: Icons.explore_rounded,
      color: Color(0xFF14B8A6),
      emoji: '\uD83C\uDF0D',
    ),
    ChallengeTemplate(
      id: 'speed_reader',
      titleKey: 'templateSpeedReader',
      descriptionKey: 'templateSpeedReaderDesc',
      type: ChallengeType.pages,
      durationDays: 7,
      targetPages: 300,
      icon: Icons.speed_rounded,
      color: Color(0xFFEF4444),
      emoji: '\uD83D\uDE80',
    ),
    ChallengeTemplate(
      id: 'book_club',
      titleKey: 'templateBookClub',
      descriptionKey: 'templateBookClubDesc',
      type: ChallengeType.readAlong,
      durationDays: 14,
      targetPages: 250,
      icon: Icons.groups_rounded,
      color: Color(0xFF6467F2),
      emoji: '\uD83D\uDCDA',
    ),
    ChallengeTemplate(
      id: 'focus_marathon',
      titleKey: 'templateFocusMarathon',
      descriptionKey: 'templateFocusMarathonDesc',
      type: ChallengeType.sprint,
      durationDays: 14,
      targetMinutes: 500,
      icon: Icons.timer_rounded,
      color: Color(0xFFF97316),
      emoji: '\uD83C\uDFAF',
    ),
  ];
}
