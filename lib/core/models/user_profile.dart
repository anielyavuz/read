import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? avatarUrl;

  // Goals & preferences
  final int dailyGoalPages;
  final List<String> favoriteGenres;
  final String? readingTime; // 'morning', 'afternoon', 'evening', 'night', 'custom'
  final String? customReadingTime; // e.g. '20:30'

  // Gamification
  final int xpTotal;
  final int xpThisWeek;
  final int streakDays;
  final DateTime? lastReadDate;
  final String currentLeague;

  // Stats
  final int booksRead;
  final int pagesRead;
  final int pagesReadToday;
  final String? pagesReadTodayDate; // 'YYYY-MM-DD'
  final int focusMinutesTotal;

  // XP penalty tracking
  final String? lastPenaltyDate; // 'YYYY-MM-DD' — last date penalty was applied

  // Subscription
  final String subscriptionTier;

  // Onboarding
  final bool onboardingCompleted;

  // Calm Mode
  final bool calmMode;

  // FCM
  final String? fcmToken;

  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.dailyGoalPages = 20,
    this.favoriteGenres = const [],
    this.readingTime,
    this.customReadingTime,
    this.xpTotal = 0,
    this.xpThisWeek = 0,
    this.streakDays = 0,
    this.lastReadDate,
    this.currentLeague = 'bronze',
    this.booksRead = 0,
    this.pagesRead = 0,
    this.pagesReadToday = 0,
    this.pagesReadTodayDate,
    this.focusMinutesTotal = 0,
    this.lastPenaltyDate,
    this.subscriptionTier = 'free',
    this.onboardingCompleted = false,
    this.calmMode = false,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      dailyGoalPages: data['dailyGoalPages'] ?? 20,
      favoriteGenres: List<String>.from(data['favoriteGenres'] ?? []),
      readingTime: data['readingTime'],
      customReadingTime: data['customReadingTime'],
      xpTotal: data['xpTotal'] ?? 0,
      xpThisWeek: data['xpThisWeek'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      lastReadDate: (data['lastReadDate'] as Timestamp?)?.toDate(),
      currentLeague: data['currentLeague'] ?? 'bronze',
      booksRead: data['booksRead'] ?? 0,
      pagesRead: data['pagesRead'] ?? 0,
      pagesReadToday: data['pagesReadToday'] ?? 0,
      pagesReadTodayDate: data['pagesReadTodayDate'],
      focusMinutesTotal: data['focusMinutesTotal'] ?? 0,
      lastPenaltyDate: data['lastPenaltyDate'],
      subscriptionTier: data['subscriptionTier'] ?? 'free',
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      calmMode: data['calmMode'] ?? false,
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'displayNameLower': displayName.toLowerCase(),
      'email': email,
      'avatarUrl': avatarUrl,
      'dailyGoalPages': dailyGoalPages,
      'favoriteGenres': favoriteGenres,
      'readingTime': readingTime,
      'customReadingTime': customReadingTime,
      'xpTotal': xpTotal,
      'xpThisWeek': xpThisWeek,
      'streakDays': streakDays,
      'lastReadDate': lastReadDate != null ? Timestamp.fromDate(lastReadDate!) : null,
      'currentLeague': currentLeague,
      'booksRead': booksRead,
      'pagesRead': pagesRead,
      'pagesReadToday': pagesReadToday,
      'pagesReadTodayDate': pagesReadTodayDate,
      'focusMinutesTotal': focusMinutesTotal,
      'lastPenaltyDate': lastPenaltyDate,
      'subscriptionTier': subscriptionTier,
      'onboardingCompleted': onboardingCompleted,
      'calmMode': calmMode,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserProfile copyWith({
    int? dailyGoalPages,
    List<String>? favoriteGenres,
    String? readingTime,
    String? customReadingTime,
    int? xpTotal,
    int? xpThisWeek,
    int? streakDays,
    String? lastPenaltyDate,
    bool? onboardingCompleted,
    bool? calmMode,
    String? fcmToken,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      dailyGoalPages: dailyGoalPages ?? this.dailyGoalPages,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      readingTime: readingTime ?? this.readingTime,
      customReadingTime: customReadingTime ?? this.customReadingTime,
      xpTotal: xpTotal ?? this.xpTotal,
      xpThisWeek: xpThisWeek ?? this.xpThisWeek,
      streakDays: streakDays ?? this.streakDays,
      lastReadDate: lastReadDate,
      currentLeague: currentLeague,
      booksRead: booksRead,
      pagesRead: pagesRead,
      pagesReadToday: pagesReadToday,
      pagesReadTodayDate: pagesReadTodayDate,
      focusMinutesTotal: focusMinutesTotal,
      lastPenaltyDate: lastPenaltyDate ?? this.lastPenaltyDate,
      subscriptionTier: subscriptionTier,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      calmMode: calmMode ?? this.calmMode,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
