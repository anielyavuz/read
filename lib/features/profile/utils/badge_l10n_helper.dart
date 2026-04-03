import '../../../l10n/generated/app_localizations.dart';

/// Resolves a badge nameKey or descriptionKey to the localized string.
/// Falls back to the key itself if no match is found.
String resolveBadgeL10n(AppLocalizations l10n, String key) {
  final map = <String, String>{
    // Reading
    'badgeFirstPage': l10n.badgeFirstPage,
    'badgeFirstPageDesc': l10n.badgeFirstPageDesc,
    'badgeFiftyPages': l10n.badgeFiftyPages,
    'badgeFiftyPagesDesc': l10n.badgeFiftyPagesDesc,
    'badgeTwoHundredPages': l10n.badgeTwoHundredPages,
    'badgeTwoHundredPagesDesc': l10n.badgeTwoHundredPagesDesc,
    'badgeFiveHundredPages': l10n.badgeFiveHundredPages,
    'badgeFiveHundredPagesDesc': l10n.badgeFiveHundredPagesDesc,
    'badgePageTurner': l10n.badgePageTurner,
    'badgePageTurnerDesc': l10n.badgePageTurnerDesc,
    'badgeMarathonReader': l10n.badgeMarathonReader,
    'badgeMarathonReaderDesc': l10n.badgeMarathonReaderDesc,
    'badgeFirstBook': l10n.badgeFirstBook,
    'badgeFirstBookDesc': l10n.badgeFirstBookDesc,
    'badgeThreeBooks': l10n.badgeThreeBooks,
    'badgeThreeBooksDesc': l10n.badgeThreeBooksDesc,
    'badgeBookworm': l10n.badgeBookworm,
    'badgeBookwormDesc': l10n.badgeBookwormDesc,
    'badgeCenturyClub': l10n.badgeCenturyClub,
    'badgeCenturyClubDesc': l10n.badgeCenturyClubDesc,
    // Streak
    'badgeGettingStarted': l10n.badgeGettingStarted,
    'badgeGettingStartedDesc': l10n.badgeGettingStartedDesc,
    'badgeThreeDayStreak': l10n.badgeThreeDayStreak,
    'badgeThreeDayStreakDesc': l10n.badgeThreeDayStreakDesc,
    'badgeFiveDayStreak': l10n.badgeFiveDayStreak,
    'badgeFiveDayStreakDesc': l10n.badgeFiveDayStreakDesc,
    'badgeOnFire': l10n.badgeOnFire,
    'badgeOnFireDesc': l10n.badgeOnFireDesc,
    'badgeTwoWeekStreak': l10n.badgeTwoWeekStreak,
    'badgeTwoWeekStreakDesc': l10n.badgeTwoWeekStreakDesc,
    'badgeUnstoppable': l10n.badgeUnstoppable,
    'badgeUnstoppableDesc': l10n.badgeUnstoppableDesc,
    'badgeLegend': l10n.badgeLegend,
    'badgeLegendDesc': l10n.badgeLegendDesc,
    'badgeImmortal': l10n.badgeImmortal,
    'badgeImmortalDesc': l10n.badgeImmortalDesc,
    // Focus
    'badgeFirstFocus': l10n.badgeFirstFocus,
    'badgeFirstFocusDesc': l10n.badgeFirstFocusDesc,
    'badgeFocusFive': l10n.badgeFocusFive,
    'badgeFocusFiveDesc': l10n.badgeFocusFiveDesc,
    'badgeFocusRegular': l10n.badgeFocusRegular,
    'badgeFocusRegularDesc': l10n.badgeFocusRegularDesc,
    'badgeFocusMaster': l10n.badgeFocusMaster,
    'badgeFocusMasterDesc': l10n.badgeFocusMasterDesc,
    'badgeFocusHour': l10n.badgeFocusHour,
    'badgeFocusHourDesc': l10n.badgeFocusHourDesc,
    'badgeFocusTenHours': l10n.badgeFocusTenHours,
    'badgeFocusTenHoursDesc': l10n.badgeFocusTenHoursDesc,
  };
  return map[key] ?? key;
}
