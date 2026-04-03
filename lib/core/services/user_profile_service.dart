import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// In-memory cache for the current user's profile.
  UserProfile? _cachedProfile;
  DateTime? _cacheTime;

  /// Cache TTL — profile is served from memory within this window.
  static const _cacheDuration = Duration(seconds: 30);

  UserProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  String? get _uid => _auth.currentUser?.uid;

  /// Returns the cached profile if still valid, otherwise fetches from Firestore.
  /// Use [forceRefresh] to bypass the cache.
  Future<UserProfile?> getProfile({bool forceRefresh = false}) async {
    if (_uid == null) return null;

    // Return cached profile if valid
    if (!forceRefresh && _cachedProfile != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheDuration && _cachedProfile!.uid == _uid) {
        return _cachedProfile;
      }
    }

    final doc = await _usersRef.doc(_uid).get();
    if (!doc.exists) return null;

    var profile = UserProfile.fromFirestore(doc);

    // --- Streak validation: reset if user missed a day (skip in calm mode) ---
    if (profile.streakDays > 0 && !profile.calmMode) {
      final lastRead = profile.lastReadDate;
      if (lastRead != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastReadDay = DateTime(lastRead.year, lastRead.month, lastRead.day);
        final daysSinceLastRead = today.difference(lastReadDay).inDays;

        // If more than 1 day has passed since last read, streak is broken
        if (daysSinceLastRead > 1) {
          await _usersRef.doc(_uid).update({'streakDays': 0});
          profile = profile.copyWith(streakDays: 0);
        }
      } else {
        // No lastReadDate but has streak — shouldn't happen, reset
        await _usersRef.doc(_uid).update({'streakDays': 0});
        profile = profile.copyWith(streakDays: 0);
      }
    }

    // --- XP penalty: deduct XP for missed daily goals ---
    profile = await _applyXpPenalty(profile);

    _cachedProfile = profile;
    _cacheTime = DateTime.now();
    return profile;
  }

  /// Apply XP penalty for each missed day since the last penalty check.
  /// - Partial miss (read but didn't hit goal): -5% of xpThisWeek
  /// - Full miss (didn't read at all): -10% of xpThisWeek
  /// Penalty is capped so xpThisWeek never goes below 0.
  /// Toggle calm mode on/off.
  Future<void> toggleCalmMode(bool enabled) async {
    if (_uid == null) return;
    await _usersRef.doc(_uid).update({'calmMode': enabled});
    invalidateCache();
  }

  Future<UserProfile> _applyXpPenalty(UserProfile profile) async {
    // No XP penalty in calm mode
    if (profile.calmMode) return profile;

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Don't penalize if already checked today
    if (profile.lastPenaltyDate == todayStr) return profile;

    // Determine the start date for penalty calculation
    DateTime penaltyStart;
    if (profile.lastPenaltyDate != null) {
      final parts = profile.lastPenaltyDate!.split('-');
      penaltyStart = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } else if (profile.lastReadDate != null) {
      penaltyStart = DateTime(
        profile.lastReadDate!.year,
        profile.lastReadDate!.month,
        profile.lastReadDate!.day,
      );
    } else {
      // No read history at all — just mark today and skip
      await _usersRef.doc(_uid).update({'lastPenaltyDate': todayStr});
      return profile.copyWith(lastPenaltyDate: todayStr);
    }

    final today = DateTime(now.year, now.month, now.day);
    final missedDays = today.difference(penaltyStart).inDays;

    // No missed days (same day or next day after last check)
    if (missedDays <= 1) {
      await _usersRef.doc(_uid).update({'lastPenaltyDate': todayStr});
      return profile.copyWith(lastPenaltyDate: todayStr);
    }

    // Calculate penalty: each fully missed day costs 10% of xpThisWeek
    // (days between last check and today, excluding today since user hasn't had a chance yet)
    final penaltyDays = missedDays - 1; // exclude today
    final penaltyPerDay = (profile.xpThisWeek * 0.10).round();
    final totalPenalty = (penaltyPerDay * penaltyDays).clamp(0, profile.xpThisWeek);

    if (totalPenalty > 0) {
      final newXpThisWeek = profile.xpThisWeek - totalPenalty;
      final newXpTotal = (profile.xpTotal - totalPenalty).clamp(0, profile.xpTotal);

      await _usersRef.doc(_uid).update({
        'xpThisWeek': newXpThisWeek,
        'xpTotal': newXpTotal,
        'lastPenaltyDate': todayStr,
      });

      return profile.copyWith(
        xpTotal: newXpTotal,
        xpThisWeek: newXpThisWeek,
        lastPenaltyDate: todayStr,
      );
    }

    // No penalty needed (xpThisWeek was 0) — just update the date
    await _usersRef.doc(_uid).update({'lastPenaltyDate': todayStr});
    return profile.copyWith(lastPenaltyDate: todayStr);
  }

  /// Clears the in-memory cache. Call after local writes that change profile data,
  /// so the next getProfile() fetches fresh data from Firestore.
  void invalidateCache() {
    _cachedProfile = null;
    _cacheTime = null;
  }

  /// Create initial user profile after sign up
  Future<UserProfile> createProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final existing = await _usersRef.doc(user.uid).get();
    if (existing.exists) {
      return UserProfile.fromFirestore(existing);
    }

    final profile = UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? '',
      email: user.email ?? '',
      avatarUrl: user.photoURL,
      createdAt: DateTime.now(),
    );

    await _usersRef.doc(user.uid).set(profile.toFirestore());
    invalidateCache();
    return profile;
  }

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    final profile = await getProfile();
    return profile?.onboardingCompleted ?? false;
  }

  /// Save daily reading goal
  Future<void> saveDailyGoal(int pages) async {
    if (_uid == null) return;
    await _usersRef.doc(_uid).update({
      'dailyGoalPages': pages,
    });
    invalidateCache();
  }

  /// Save favorite genres
  Future<void> saveGenres(List<String> genres) async {
    if (_uid == null) return;
    await _usersRef.doc(_uid).update({
      'favoriteGenres': genres,
    });
    invalidateCache();
  }

  /// Save reading time preference (does NOT mark onboarding as complete)
  Future<void> saveReadingTimeAndFinish({
    required String readingTime,
    String? customReadingTime,
  }) async {
    if (_uid == null) return;
    await _usersRef.doc(_uid).update({
      'readingTime': readingTime,
      'customReadingTime': customReadingTime,
    });
    invalidateCache();
  }

  /// Mark onboarding as complete (called after reader profile quiz)
  Future<void> completeOnboarding() async {
    if (_uid == null) return;
    await _usersRef.doc(_uid).update({
      'onboardingCompleted': true,
    });
    invalidateCache();
  }

  /// Delete all user data (profile + library)
  Future<void> deleteUserData() async {
    if (_uid == null) return;

    // Delete user's library subcollection
    final libraryRef = _firestore
        .collection('userBooks')
        .doc(_uid)
        .collection('library');
    final libraryDocs = await libraryRef.get();
    for (final doc in libraryDocs.docs) {
      await doc.reference.delete();
    }

    // Delete userBooks parent doc
    await _firestore.collection('userBooks').doc(_uid).delete();

    // Delete user profile
    await _usersRef.doc(_uid).delete();
    invalidateCache();
  }

  /// Save FCM token
  Future<void> saveFcmToken(String token) async {
    if (_uid == null) return;
    await _usersRef.doc(_uid).update({
      'fcmToken': token,
    });
    invalidateCache();
  }

  /// Update display name in Firestore and Firebase Auth
  Future<void> updateDisplayName(String name) async {
    if (_uid == null) return;
    try {
      await _usersRef.doc(_uid).update({
        'displayName': name,
        'displayNameLower': name.toLowerCase(),
      });
      await _auth.currentUser?.updateDisplayName(name);
      invalidateCache();
    } catch (e) {
      rethrow;
    }
  }
}
