import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'league_service.dart';

/// Result of an XP award operation.
class XpAwardResult {
  final int xpEarned;
  final bool streakUpdated;
  final int newStreakDays;
  final bool dailyGoalReached;

  const XpAwardResult({
    this.xpEarned = 0,
    this.streakUpdated = false,
    this.newStreakDays = 0,
    this.dailyGoalReached = false,
  });
}

/// Centralized service for awarding XP and managing streaks.
///
/// XP rules (from CLAUDE.md):
///   +10 XP  per page read
///   +50 XP  daily reading goal completed
///   +200 XP book finished
///   +25 XP  streak maintained (new day)
///   x1.5 XP for 7+ day streak (on page XP only)
///
/// Focus Mode XP is handled separately by [FocusSessionService].
class XpService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LeagueService _leagueService;

  XpService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required LeagueService leagueService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _leagueService = leagueService;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  /// Awards XP for reading pages and handles streak check/update.
  ///
  /// [pageDelta] is the number of NEW pages read (currentPage - previousPage).
  /// Returns an [XpAwardResult] with the total XP earned and streak info.
  Future<XpAwardResult> awardPagesXp(int pageDelta) async {
    if (_uid == null || pageDelta <= 0) {
      return const XpAwardResult();
    }

    // Reset xpThisWeek if a new Monday-to-Sunday week has started
    await _leagueService.resetWeeklyXpIfNeeded();

    final userDoc = await _userDoc.get();
    final data = userDoc.data() ?? {};
    final isCalmMode = data['calmMode'] == true;

    // In calm mode: update page tracking only, skip XP/streak/league
    if (isCalmMode) {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final storedDate = data['pagesReadTodayDate'] as String?;
      final isSameDay = storedDate == todayStr;

      final updates = <String, dynamic>{
        'pagesRead': FieldValue.increment(pageDelta),
        'lastReadDate': Timestamp.fromDate(now),
        'pagesReadTodayDate': todayStr,
      };
      if (isSameDay) {
        updates['pagesReadToday'] = FieldValue.increment(pageDelta);
      } else {
        updates['pagesReadToday'] = pageDelta;
      }
      await _userDoc.update(updates);
      return const XpAwardResult();
    }

    final lastReadDate = (data['lastReadDate'] as Timestamp?)?.toDate();
    final currentStreak = data['streakDays'] as int? ?? 0;
    final dailyGoalPages = data['dailyGoalPages'] as int? ?? 20;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // --- Base page XP ---
    int pageXp = pageDelta * 10;

    // --- Streak multiplier: 1.5x page XP for 7+ day streak ---
    if (currentStreak >= 7) {
      pageXp = (pageXp * 1.5).round();
    }

    // --- Firestore update ---
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final storedDate = data['pagesReadTodayDate'] as String?;
    final isSameDay = storedDate == todayStr;

    // Calculate what pagesReadToday will be after this update
    final previousPagesToday = isSameDay ? (data['pagesReadToday'] as int? ?? 0) : 0;
    final newPagesToday = previousPagesToday + pageDelta;

    // --- Streak logic: only advance when daily goal is reached ---
    bool streakUpdated = false;
    int newStreak = currentStreak;
    // Goal was NOT reached before, but IS reached now
    final goalJustReached = previousPagesToday < dailyGoalPages &&
        newPagesToday >= dailyGoalPages;

    if (goalJustReached) {
      if (lastReadDate == null) {
        newStreak = 1;
      } else {
        final lastDay = DateTime(
          lastReadDate.year,
          lastReadDate.month,
          lastReadDate.day,
        );
        if (lastDay.isBefore(today)) {
          final yesterday = today.subtract(const Duration(days: 1));
          // Check if yesterday's goal was completed (streak was already incremented yesterday)
          newStreak = (lastDay == yesterday || lastDay == today)
              ? currentStreak + 1
              : 1;
        } else {
          // Same day — shouldn't happen if previousPagesToday < goal, but be safe
          newStreak = currentStreak + 1;
        }
      }
      streakUpdated = true;
    }

    // --- Total XP ---
    int totalXp = pageXp;
    if (goalJustReached) {
      totalXp += 25; // +25 XP streak maintenance bonus
    }

    final updates = <String, dynamic>{
      'xpTotal': FieldValue.increment(totalXp),
      'xpThisWeek': FieldValue.increment(totalXp),
      'pagesRead': FieldValue.increment(pageDelta),
      'lastReadDate': Timestamp.fromDate(now),
      'pagesReadTodayDate': todayStr,
    };

    if (isSameDay) {
      updates['pagesReadToday'] = FieldValue.increment(pageDelta);
    } else {
      updates['pagesReadToday'] = pageDelta;
    }

    if (streakUpdated) {
      updates['streakDays'] = newStreak;
    }

    await _userDoc.update(updates);
    await _leagueService.addXpToLeague(totalXp);

    final effectiveStreak = streakUpdated ? newStreak : currentStreak;
    return XpAwardResult(
      xpEarned: totalXp,
      streakUpdated: streakUpdated,
      newStreakDays: effectiveStreak,
      dailyGoalReached: goalJustReached,
    );
  }

  /// Ensures weekly XP is reset if needed, then awards XP with optional extra fields.
  /// In calm mode: skips XP and league, but still applies tracking-related [extraUpdates].
  Future<void> _awardXp(int xp, [Map<String, dynamic>? extraUpdates]) async {
    final userDoc = await _userDoc.get();
    final data = userDoc.data() ?? {};
    final isCalmMode = data['calmMode'] == true;

    if (isCalmMode) {
      // Only apply non-XP extra updates (e.g. booksRead increment)
      if (extraUpdates != null && extraUpdates.isNotEmpty) {
        await _userDoc.update(extraUpdates);
      }
      return;
    }

    await _leagueService.resetWeeklyXpIfNeeded();
    final updates = <String, dynamic>{
      'xpTotal': FieldValue.increment(xp),
      'xpThisWeek': FieldValue.increment(xp),
      ...?extraUpdates,
    };
    await _userDoc.update(updates);
    await _leagueService.addXpToLeague(xp);
  }

  /// Awards +200 XP for finishing a book.
  Future<int> awardBookFinishedXp() async {
    if (_uid == null) return 0;
    const xp = 200;
    await _awardXp(xp, {'booksRead': FieldValue.increment(1)});
    return xp;
  }

  /// Awards +50 XP for completing the daily reading goal (min 20 minutes).
  Future<int> awardDailyGoalXp() async {
    if (_uid == null) return 0;
    const xp = 50;
    await _awardXp(xp);
    return xp;
  }

  /// Awards +50 XP for joining a challenge.
  Future<int> awardChallengeJoinXp() async {
    if (_uid == null) return 0;
    const xp = 50;
    await _awardXp(xp);
    return xp;
  }

  /// Awards +150 XP for completing a challenge target.
  Future<int> awardChallengeCompleteXp() async {
    if (_uid == null) return 0;
    const xp = 150;
    await _awardXp(xp);
    return xp;
  }

  /// Awards +100 XP for completing a ReadBrain quiz with 70%+ score.
  Future<int> awardQuizXp() async {
    if (_uid == null) return 0;
    const xp = 100;
    await _awardXp(xp);
    return xp;
  }
}
