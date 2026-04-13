import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ReadO'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'READ. COMPETE. WIN.'**
  String get tagline;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'The reading app for bookworms. Track your reading, compete with friends, level up your library.'**
  String get appDescription;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @joinTheLeague.
  ///
  /// In en, this message translates to:
  /// **'Join the League'**
  String get joinTheLeague;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of readers competing to read more'**
  String get signUpSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @createPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPasswordHint;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @alreadyHaveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccountQuestion;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your league is waiting for you'**
  String get signInSubtitle;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @chooseYourCompanion.
  ///
  /// In en, this message translates to:
  /// **'Choose your reading buddy'**
  String get chooseYourCompanion;

  /// No description provided for @companionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your reading buddy will grow as you read more books'**
  String get companionSubtitle;

  /// No description provided for @nameYourCompanion.
  ///
  /// In en, this message translates to:
  /// **'Name your buddy'**
  String get nameYourCompanion;

  /// No description provided for @companionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Give your buddy a name'**
  String get companionNameHint;

  /// No description provided for @companionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Your buddy needs a name!'**
  String get companionNameRequired;

  /// No description provided for @breedGoldenRetriever.
  ///
  /// In en, this message translates to:
  /// **'Golden Retriever'**
  String get breedGoldenRetriever;

  /// No description provided for @breedCorgi.
  ///
  /// In en, this message translates to:
  /// **'Corgi'**
  String get breedCorgi;

  /// No description provided for @breedShibaInu.
  ///
  /// In en, this message translates to:
  /// **'Shiba Inu'**
  String get breedShibaInu;

  /// No description provided for @breedPoodle.
  ///
  /// In en, this message translates to:
  /// **'Poodle'**
  String get breedPoodle;

  /// No description provided for @breedDalmatian.
  ///
  /// In en, this message translates to:
  /// **'Dalmatian'**
  String get breedDalmatian;

  /// No description provided for @breedSiberianHusky.
  ///
  /// In en, this message translates to:
  /// **'Siberian Husky'**
  String get breedSiberianHusky;

  /// No description provided for @breedGermanShepherd.
  ///
  /// In en, this message translates to:
  /// **'German Shepherd'**
  String get breedGermanShepherd;

  /// No description provided for @breedRottweiler.
  ///
  /// In en, this message translates to:
  /// **'Rottweiler'**
  String get breedRottweiler;

  /// No description provided for @breedBorderCollie.
  ///
  /// In en, this message translates to:
  /// **'Border Collie'**
  String get breedBorderCollie;

  /// No description provided for @breedKangal.
  ///
  /// In en, this message translates to:
  /// **'Kangal'**
  String get breedKangal;

  /// No description provided for @breedSaintBernard.
  ///
  /// In en, this message translates to:
  /// **'Saint Bernard'**
  String get breedSaintBernard;

  /// No description provided for @traitStreakLover.
  ///
  /// In en, this message translates to:
  /// **'Streak Lover'**
  String get traitStreakLover;

  /// No description provided for @traitSprintChampion.
  ///
  /// In en, this message translates to:
  /// **'Sprint Champion'**
  String get traitSprintChampion;

  /// No description provided for @traitLoneWolf.
  ///
  /// In en, this message translates to:
  /// **'Lone Wolf'**
  String get traitLoneWolf;

  /// No description provided for @traitQuizMaster.
  ///
  /// In en, this message translates to:
  /// **'Quiz Master'**
  String get traitQuizMaster;

  /// No description provided for @traitChallenger.
  ///
  /// In en, this message translates to:
  /// **'Challenger'**
  String get traitChallenger;

  /// No description provided for @traitDramatic.
  ///
  /// In en, this message translates to:
  /// **'Drama Queen'**
  String get traitDramatic;

  /// No description provided for @traitDisciplined.
  ///
  /// In en, this message translates to:
  /// **'Disciplined'**
  String get traitDisciplined;

  /// No description provided for @traitEndurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get traitEndurance;

  /// No description provided for @traitGoalCrusher.
  ///
  /// In en, this message translates to:
  /// **'Goal Crusher'**
  String get traitGoalCrusher;

  /// No description provided for @traitLeagueWarrior.
  ///
  /// In en, this message translates to:
  /// **'League Warrior'**
  String get traitLeagueWarrior;

  /// No description provided for @traitZenReader.
  ///
  /// In en, this message translates to:
  /// **'Zen Reader'**
  String get traitZenReader;

  /// No description provided for @traitStreakLoverDesc.
  ///
  /// In en, this message translates to:
  /// **'Never breaks a streak! Needs daily pages.'**
  String get traitStreakLoverDesc;

  /// No description provided for @traitSprintChampionDesc.
  ///
  /// In en, this message translates to:
  /// **'Short & fast! Loves quick reading sprints.'**
  String get traitSprintChampionDesc;

  /// No description provided for @traitLoneWolfDesc.
  ///
  /// In en, this message translates to:
  /// **'Reads at own pace. Deep & focused sessions.'**
  String get traitLoneWolfDesc;

  /// No description provided for @traitQuizMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Brain power! Craves quizzes after every book.'**
  String get traitQuizMasterDesc;

  /// No description provided for @traitChallengerDesc.
  ///
  /// In en, this message translates to:
  /// **'Born to compete! Lives for challenges.'**
  String get traitChallengerDesc;

  /// No description provided for @traitDramaticDesc.
  ///
  /// In en, this message translates to:
  /// **'Over-the-top reactions to everything!'**
  String get traitDramaticDesc;

  /// No description provided for @traitDisciplinedDesc.
  ///
  /// In en, this message translates to:
  /// **'Strict routine. No excuses, no days off.'**
  String get traitDisciplinedDesc;

  /// No description provided for @traitEnduranceDesc.
  ///
  /// In en, this message translates to:
  /// **'Marathon reader. Long focus sessions only.'**
  String get traitEnduranceDesc;

  /// No description provided for @traitGoalCrusherDesc.
  ///
  /// In en, this message translates to:
  /// **'Obsessed with weekly targets. Never misses.'**
  String get traitGoalCrusherDesc;

  /// No description provided for @traitLeagueWarriorDesc.
  ///
  /// In en, this message translates to:
  /// **'Climbs the leaderboard. Top 10 or bust!'**
  String get traitLeagueWarriorDesc;

  /// No description provided for @traitZenReaderDesc.
  ///
  /// In en, this message translates to:
  /// **'No rush, no stress. Enjoys the journey.'**
  String get traitZenReaderDesc;

  /// No description provided for @goalNoteStreakLover.
  ///
  /// In en, this message translates to:
  /// **'Your Golden wants to read every single day!'**
  String get goalNoteStreakLover;

  /// No description provided for @goalNoteSprintChampion.
  ///
  /// In en, this message translates to:
  /// **'Your Corgi prefers quick, fun reading bursts!'**
  String get goalNoteSprintChampion;

  /// No description provided for @goalNoteLoneWolf.
  ///
  /// In en, this message translates to:
  /// **'Your Shiba reads deep — quality over quantity.'**
  String get goalNoteLoneWolf;

  /// No description provided for @goalNoteQuizMaster.
  ///
  /// In en, this message translates to:
  /// **'Your Poodle wants to understand every page!'**
  String get goalNoteQuizMaster;

  /// No description provided for @goalNoteChallenger.
  ///
  /// In en, this message translates to:
  /// **'Your Dalmatian is hungry for big goals!'**
  String get goalNoteChallenger;

  /// No description provided for @goalNoteDramatic.
  ///
  /// In en, this message translates to:
  /// **'Your Husky will dramatically cry if you skip!'**
  String get goalNoteDramatic;

  /// No description provided for @goalNoteDisciplined.
  ///
  /// In en, this message translates to:
  /// **'Your Shepherd expects military-level discipline!'**
  String get goalNoteDisciplined;

  /// No description provided for @goalNoteEndurance.
  ///
  /// In en, this message translates to:
  /// **'Your Rottweiler trains hard — more pages!'**
  String get goalNoteEndurance;

  /// No description provided for @goalNoteGoalCrusher.
  ///
  /// In en, this message translates to:
  /// **'Your Collie won\'t rest until the goal is hit!'**
  String get goalNoteGoalCrusher;

  /// No description provided for @goalNoteLeagueWarrior.
  ///
  /// In en, this message translates to:
  /// **'Your Kangal fights for every league point!'**
  String get goalNoteLeagueWarrior;

  /// No description provided for @goalNoteZenReader.
  ///
  /// In en, this message translates to:
  /// **'Your Saint Bernard says: slow and steady wins.'**
  String get goalNoteZenReader;

  /// No description provided for @setDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Set your daily reading goal'**
  String get setDailyGoal;

  /// No description provided for @goalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you and track your streak'**
  String get goalSubtitle;

  /// No description provided for @pagesPerDay.
  ///
  /// In en, this message translates to:
  /// **'PAGES PER DAY'**
  String get pagesPerDay;

  /// No description provided for @goalMotivationPrefix.
  ///
  /// In en, this message translates to:
  /// **'Readers who set goals read '**
  String get goalMotivationPrefix;

  /// No description provided for @goalMotivationHighlight.
  ///
  /// In en, this message translates to:
  /// **'3x more'**
  String get goalMotivationHighlight;

  /// No description provided for @goalMotivationSuffix.
  ///
  /// In en, this message translates to:
  /// **' than those who don\'t.'**
  String get goalMotivationSuffix;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get errorUserNotFound;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get errorWrongPassword;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get errorTooManyRequests;

  /// No description provided for @errorNetworkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get errorNetworkRequestFailed;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get errorFieldRequired;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get passwordResetSent;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @pickFavoriteGenres.
  ///
  /// In en, this message translates to:
  /// **'Pick your favorite genres'**
  String get pickFavoriteGenres;

  /// No description provided for @genreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your favorites — you can select more than one'**
  String get genreSubtitle;

  /// No description provided for @genreFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get genreFantasy;

  /// No description provided for @genreRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get genreRomance;

  /// No description provided for @genreThriller.
  ///
  /// In en, this message translates to:
  /// **'Thriller'**
  String get genreThriller;

  /// No description provided for @genreSciFi.
  ///
  /// In en, this message translates to:
  /// **'Sci-Fi'**
  String get genreSciFi;

  /// No description provided for @genreMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get genreMystery;

  /// No description provided for @genreNonFiction.
  ///
  /// In en, this message translates to:
  /// **'Non-Fiction'**
  String get genreNonFiction;

  /// No description provided for @genreSelfHelp.
  ///
  /// In en, this message translates to:
  /// **'Self-Help'**
  String get genreSelfHelp;

  /// No description provided for @genreHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get genreHistory;

  /// No description provided for @genreHorror.
  ///
  /// In en, this message translates to:
  /// **'Horror'**
  String get genreHorror;

  /// No description provided for @genrePoetry.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get genrePoetry;

  /// No description provided for @genreBiography.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get genreBiography;

  /// No description provided for @genreYoungAdult.
  ///
  /// In en, this message translates to:
  /// **'Young Adult'**
  String get genreYoungAdult;

  /// No description provided for @genreSelectMin.
  ///
  /// In en, this message translates to:
  /// **'Select at least 3 genres'**
  String get genreSelectMin;

  /// No description provided for @whenDoYouRead.
  ///
  /// In en, this message translates to:
  /// **'When do you prefer to read?'**
  String get whenDoYouRead;

  /// No description provided for @readingTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send smart reminders at the perfect time'**
  String get readingTimeSubtitle;

  /// No description provided for @timeMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get timeMorning;

  /// No description provided for @timeMorningDesc.
  ///
  /// In en, this message translates to:
  /// **'6 AM - 12 PM'**
  String get timeMorningDesc;

  /// No description provided for @timeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get timeAfternoon;

  /// No description provided for @timeAfternoonDesc.
  ///
  /// In en, this message translates to:
  /// **'12 PM - 5 PM'**
  String get timeAfternoonDesc;

  /// No description provided for @timeEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get timeEvening;

  /// No description provided for @timeEveningDesc.
  ///
  /// In en, this message translates to:
  /// **'5 PM - 9 PM'**
  String get timeEveningDesc;

  /// No description provided for @timeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get timeNight;

  /// No description provided for @timeNightDesc.
  ///
  /// In en, this message translates to:
  /// **'9 PM - 12 AM'**
  String get timeNightDesc;

  /// No description provided for @readyToStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go!'**
  String get readyToStart;

  /// No description provided for @readingTimeMotivationPrefix.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you at the '**
  String get readingTimeMotivationPrefix;

  /// No description provided for @readingTimeMotivationHighlight.
  ///
  /// In en, this message translates to:
  /// **'right moment'**
  String get readingTimeMotivationHighlight;

  /// No description provided for @readingTimeMotivationSuffix.
  ///
  /// In en, this message translates to:
  /// **' to build your reading habit.'**
  String get readingTimeMotivationSuffix;

  /// No description provided for @timeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Time'**
  String get timeCustom;

  /// No description provided for @timeCustomDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick your own time'**
  String get timeCustomDesc;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get navFocus;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning, {name}'**
  String goodMorning(String name);

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon, {name}'**
  String goodAfternoon(String name);

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening, {name}'**
  String goodEvening(String name);

  /// No description provided for @readyForToday.
  ///
  /// In en, this message translates to:
  /// **'Ready for today\'s reading?'**
  String get readyForToday;

  /// No description provided for @yourCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your Companion'**
  String get yourCompanion;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String levelLabel(int level);

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String dayStreak(int count);

  /// No description provided for @streakStartPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start your streak!'**
  String get streakStartPrompt;

  /// No description provided for @xpTotal.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String xpTotal(int xp);

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgress;

  /// No description provided for @pagesProgress.
  ///
  /// In en, this message translates to:
  /// **'{read} / {goal} pages'**
  String pagesProgress(int read, int goal);

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get startReading;

  /// No description provided for @addBook.
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get addBook;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @toBeRead.
  ///
  /// In en, this message translates to:
  /// **'To Be Read'**
  String get toBeRead;

  /// No description provided for @emptyReading.
  ///
  /// In en, this message translates to:
  /// **'No books in progress.\nSearch and add a book to start reading!'**
  String get emptyReading;

  /// No description provided for @emptyFinished.
  ///
  /// In en, this message translates to:
  /// **'No finished books yet.\nComplete a book to see it here!'**
  String get emptyFinished;

  /// No description provided for @emptyTbr.
  ///
  /// In en, this message translates to:
  /// **'Your reading list is empty.\nAdd books you want to read later!'**
  String get emptyTbr;

  /// No description provided for @searchBooks.
  ///
  /// In en, this message translates to:
  /// **'Search Books'**
  String get searchBooks;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title, author, or ISBN'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get noResults;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @cantFindBook.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your book?'**
  String get cantFindBook;

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get addManually;

  /// No description provided for @addBookManually.
  ///
  /// In en, this message translates to:
  /// **'Add Book Manually'**
  String get addBookManually;

  /// No description provided for @bookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Title'**
  String get bookTitle;

  /// No description provided for @authorName.
  ///
  /// In en, this message translates to:
  /// **'Author Name'**
  String get authorName;

  /// No description provided for @pageCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Page Count'**
  String get pageCountLabel;

  /// No description provided for @addStatus.
  ///
  /// In en, this message translates to:
  /// **'Add as'**
  String get addStatus;

  /// No description provided for @currentPageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which page are you on?'**
  String get currentPageQuestion;

  /// No description provided for @bookAdded.
  ///
  /// In en, this message translates to:
  /// **'Book added!'**
  String get bookAdded;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @pleaseEnterAuthor.
  ///
  /// In en, this message translates to:
  /// **'Please enter an author'**
  String get pleaseEnterAuthor;

  /// No description provided for @pleaseEnterPageCount.
  ///
  /// In en, this message translates to:
  /// **'Please enter page count'**
  String get pleaseEnterPageCount;

  /// No description provided for @addToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get addToLibrary;

  /// No description provided for @currentlyReading.
  ///
  /// In en, this message translates to:
  /// **'Currently Reading'**
  String get currentlyReading;

  /// No description provided for @wantToRead.
  ///
  /// In en, this message translates to:
  /// **'Want to Read'**
  String get wantToRead;

  /// No description provided for @bookDetails.
  ///
  /// In en, this message translates to:
  /// **'Book Details'**
  String get bookDetails;

  /// No description provided for @bookNotFound.
  ///
  /// In en, this message translates to:
  /// **'Book not found'**
  String get bookNotFound;

  /// No description provided for @pagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String pagesCount(int count);

  /// No description provided for @readingProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading Progress'**
  String get readingProgress;

  /// No description provided for @pagesOf.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total} pages'**
  String pagesOf(int current, int total);

  /// No description provided for @updateProgress.
  ///
  /// In en, this message translates to:
  /// **'Update Progress'**
  String get updateProgress;

  /// No description provided for @markAsFinished.
  ///
  /// In en, this message translates to:
  /// **'I Finished This Book'**
  String get markAsFinished;

  /// No description provided for @finishBookConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish Book'**
  String get finishBookConfirmTitle;

  /// No description provided for @finishBookConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this book as finished?'**
  String get finishBookConfirmMessage;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page number'**
  String get pageNumber;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @focusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusMode;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmMessage;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data, reading progress, and achievements will be deleted.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deleteAccountButton;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get accountDeleted;

  /// No description provided for @reauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your identity'**
  String get reauthRequired;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @reauthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get reauthFailed;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @startFocus.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get startFocus;

  /// No description provided for @pauseFocus.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseFocus;

  /// No description provided for @resumeFocus.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeFocus;

  /// No description provided for @stopFocus.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopFocus;

  /// No description provided for @selectBook.
  ///
  /// In en, this message translates to:
  /// **'Select a book'**
  String get selectBook;

  /// No description provided for @freeTimer.
  ///
  /// In en, this message translates to:
  /// **'Free Timer'**
  String get freeTimer;

  /// No description provided for @pomodoroTimer.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro 25min'**
  String get pomodoroTimer;

  /// No description provided for @goalTimer.
  ///
  /// In en, this message translates to:
  /// **'Goal-based'**
  String get goalTimer;

  /// No description provided for @todayFocusTime.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Focus'**
  String get todayFocusTime;

  /// No description provided for @focusMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String focusMinutes(int minutes);

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete!'**
  String get sessionComplete;

  /// No description provided for @pagesReadInSession.
  ///
  /// In en, this message translates to:
  /// **'Pages read'**
  String get pagesReadInSession;

  /// No description provided for @whatPageAreYouOn.
  ///
  /// In en, this message translates to:
  /// **'What page are you on?'**
  String get whatPageAreYouOn;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Was'**
  String get previousPage;

  /// No description provided for @puppyCareEarned.
  ///
  /// In en, this message translates to:
  /// **'Buddy care'**
  String get puppyCareEarned;

  /// No description provided for @xpEarned.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String xpEarned(int xp);

  /// No description provided for @saveAndClose.
  ///
  /// In en, this message translates to:
  /// **'Save & Close'**
  String get saveAndClose;

  /// No description provided for @noBookSelected.
  ///
  /// In en, this message translates to:
  /// **'No books currently being read'**
  String get noBookSelected;

  /// No description provided for @selectBookForFocus.
  ///
  /// In en, this message translates to:
  /// **'Select a book to focus on'**
  String get selectBookForFocus;

  /// No description provided for @puppySnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get puppySnack;

  /// No description provided for @puppyWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get puppyWalk;

  /// No description provided for @puppyPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get puppyPlay;

  /// No description provided for @puppyFeast.
  ///
  /// In en, this message translates to:
  /// **'Feast'**
  String get puppyFeast;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @sessionDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String sessionDuration(int minutes);

  /// No description provided for @profileStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileStats;

  /// No description provided for @totalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXp;

  /// No description provided for @weeklyXp.
  ///
  /// In en, this message translates to:
  /// **'Weekly XP'**
  String get weeklyXp;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @daysStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysStreak(int count);

  /// No description provided for @booksReadStat.
  ///
  /// In en, this message translates to:
  /// **'Books Read'**
  String get booksReadStat;

  /// No description provided for @pagesReadStat.
  ///
  /// In en, this message translates to:
  /// **'Pages Read'**
  String get pagesReadStat;

  /// No description provided for @focusTimeStat.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTimeStat;

  /// No description provided for @leagueStat.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get leagueStat;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications Enabled'**
  String get notificationsEnabled;

  /// No description provided for @yourCompanionProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Companion'**
  String get yourCompanionProfile;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @profileLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String profileLevel(int level);

  /// No description provided for @xpEarnedToast.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP earned!'**
  String xpEarnedToast(int xp);

  /// No description provided for @streakMaintained.
  ///
  /// In en, this message translates to:
  /// **'Streak maintained! {days} days'**
  String streakMaintained(int days);

  /// No description provided for @bookFinishedXp.
  ///
  /// In en, this message translates to:
  /// **'+200 XP for finishing!'**
  String get bookFinishedXp;

  /// No description provided for @leagueBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get leagueBronze;

  /// No description provided for @leagueSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get leagueSilver;

  /// No description provided for @leagueGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get leagueGold;

  /// No description provided for @leaguePlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get leaguePlatinum;

  /// No description provided for @leagueDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get leagueDiamond;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @badgesEarned.
  ///
  /// In en, this message translates to:
  /// **'{count} earned'**
  String badgesEarned(int count);

  /// No description provided for @newBadgeEarned.
  ///
  /// In en, this message translates to:
  /// **'New Badge Earned!'**
  String get newBadgeEarned;

  /// No description provided for @badgeFirstPage.
  ///
  /// In en, this message translates to:
  /// **'First Page'**
  String get badgeFirstPage;

  /// No description provided for @badgeFirstPageDesc.
  ///
  /// In en, this message translates to:
  /// **'Read your first page'**
  String get badgeFirstPageDesc;

  /// No description provided for @badgeFiftyPages.
  ///
  /// In en, this message translates to:
  /// **'Warm Up'**
  String get badgeFiftyPages;

  /// No description provided for @badgeFiftyPagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Read 50 pages'**
  String get badgeFiftyPagesDesc;

  /// No description provided for @badgeTwoHundredPages.
  ///
  /// In en, this message translates to:
  /// **'Getting Into It'**
  String get badgeTwoHundredPages;

  /// No description provided for @badgeTwoHundredPagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Read 200 pages'**
  String get badgeTwoHundredPagesDesc;

  /// No description provided for @badgeFiveHundredPages.
  ///
  /// In en, this message translates to:
  /// **'Page Collector'**
  String get badgeFiveHundredPages;

  /// No description provided for @badgeFiveHundredPagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Read 500 pages'**
  String get badgeFiveHundredPagesDesc;

  /// No description provided for @badgePageTurner.
  ///
  /// In en, this message translates to:
  /// **'Page Turner'**
  String get badgePageTurner;

  /// No description provided for @badgePageTurnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Read 1,000 pages'**
  String get badgePageTurnerDesc;

  /// No description provided for @badgeMarathonReader.
  ///
  /// In en, this message translates to:
  /// **'Marathon Reader'**
  String get badgeMarathonReader;

  /// No description provided for @badgeMarathonReaderDesc.
  ///
  /// In en, this message translates to:
  /// **'Read 10,000 pages'**
  String get badgeMarathonReaderDesc;

  /// No description provided for @badgeFirstBook.
  ///
  /// In en, this message translates to:
  /// **'First Finish'**
  String get badgeFirstBook;

  /// No description provided for @badgeFirstBookDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish your first book'**
  String get badgeFirstBookDesc;

  /// No description provided for @badgeThreeBooks.
  ///
  /// In en, this message translates to:
  /// **'Hat Trick'**
  String get badgeThreeBooks;

  /// No description provided for @badgeThreeBooksDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish 3 books'**
  String get badgeThreeBooksDesc;

  /// No description provided for @badgeBookworm.
  ///
  /// In en, this message translates to:
  /// **'Bookworm'**
  String get badgeBookworm;

  /// No description provided for @badgeBookwormDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish 10 books'**
  String get badgeBookwormDesc;

  /// No description provided for @badgeCenturyClub.
  ///
  /// In en, this message translates to:
  /// **'Century Club'**
  String get badgeCenturyClub;

  /// No description provided for @badgeCenturyClubDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish 100 books'**
  String get badgeCenturyClubDesc;

  /// No description provided for @badgeGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get badgeGettingStarted;

  /// No description provided for @badgeGettingStartedDesc.
  ///
  /// In en, this message translates to:
  /// **'2-day reading streak'**
  String get badgeGettingStartedDesc;

  /// No description provided for @badgeThreeDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Three\'s a Charm'**
  String get badgeThreeDayStreak;

  /// No description provided for @badgeThreeDayStreakDesc.
  ///
  /// In en, this message translates to:
  /// **'3-day reading streak'**
  String get badgeThreeDayStreakDesc;

  /// No description provided for @badgeFiveDayStreak.
  ///
  /// In en, this message translates to:
  /// **'High Five'**
  String get badgeFiveDayStreak;

  /// No description provided for @badgeFiveDayStreakDesc.
  ///
  /// In en, this message translates to:
  /// **'5-day reading streak'**
  String get badgeFiveDayStreakDesc;

  /// No description provided for @badgeOnFire.
  ///
  /// In en, this message translates to:
  /// **'On Fire'**
  String get badgeOnFire;

  /// No description provided for @badgeOnFireDesc.
  ///
  /// In en, this message translates to:
  /// **'7-day reading streak'**
  String get badgeOnFireDesc;

  /// No description provided for @badgeTwoWeekStreak.
  ///
  /// In en, this message translates to:
  /// **'Two Weeks Strong'**
  String get badgeTwoWeekStreak;

  /// No description provided for @badgeTwoWeekStreakDesc.
  ///
  /// In en, this message translates to:
  /// **'14-day reading streak'**
  String get badgeTwoWeekStreakDesc;

  /// No description provided for @badgeUnstoppable.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get badgeUnstoppable;

  /// No description provided for @badgeUnstoppableDesc.
  ///
  /// In en, this message translates to:
  /// **'30-day reading streak'**
  String get badgeUnstoppableDesc;

  /// No description provided for @badgeLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get badgeLegend;

  /// No description provided for @badgeLegendDesc.
  ///
  /// In en, this message translates to:
  /// **'100-day reading streak'**
  String get badgeLegendDesc;

  /// No description provided for @badgeImmortal.
  ///
  /// In en, this message translates to:
  /// **'Immortal'**
  String get badgeImmortal;

  /// No description provided for @badgeImmortalDesc.
  ///
  /// In en, this message translates to:
  /// **'365-day reading streak'**
  String get badgeImmortalDesc;

  /// No description provided for @badgeFirstFocus.
  ///
  /// In en, this message translates to:
  /// **'First Focus'**
  String get badgeFirstFocus;

  /// No description provided for @badgeFirstFocusDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete your first focus session'**
  String get badgeFirstFocusDesc;

  /// No description provided for @badgeFocusFive.
  ///
  /// In en, this message translates to:
  /// **'Focus Regular'**
  String get badgeFocusFive;

  /// No description provided for @badgeFocusFiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 focus sessions'**
  String get badgeFocusFiveDesc;

  /// No description provided for @badgeFocusRegular.
  ///
  /// In en, this message translates to:
  /// **'Deep Reader'**
  String get badgeFocusRegular;

  /// No description provided for @badgeFocusRegularDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 20 focus sessions'**
  String get badgeFocusRegularDesc;

  /// No description provided for @badgeFocusMaster.
  ///
  /// In en, this message translates to:
  /// **'Focus Master'**
  String get badgeFocusMaster;

  /// No description provided for @badgeFocusMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 focus sessions'**
  String get badgeFocusMasterDesc;

  /// No description provided for @badgeFocusHour.
  ///
  /// In en, this message translates to:
  /// **'First Hour'**
  String get badgeFocusHour;

  /// No description provided for @badgeFocusHourDesc.
  ///
  /// In en, this message translates to:
  /// **'Spend 1 hour in focus mode'**
  String get badgeFocusHourDesc;

  /// No description provided for @badgeFocusTenHours.
  ///
  /// In en, this message translates to:
  /// **'Ten Hour Club'**
  String get badgeFocusTenHours;

  /// No description provided for @badgeFocusTenHoursDesc.
  ///
  /// In en, this message translates to:
  /// **'Spend 10 hours in focus mode'**
  String get badgeFocusTenHoursDesc;

  /// No description provided for @badgePaigesBestFriend.
  ///
  /// In en, this message translates to:
  /// **'Paige\'s Best Friend'**
  String get badgePaigesBestFriend;

  /// No description provided for @badgePaigesBestFriendDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach companion level 25'**
  String get badgePaigesBestFriendDesc;

  /// No description provided for @puppyDiary.
  ///
  /// In en, this message translates to:
  /// **'Buddy Diary'**
  String get puppyDiary;

  /// No description provided for @viewPuppyDiary.
  ///
  /// In en, this message translates to:
  /// **'View Buddy Diary'**
  String get viewPuppyDiary;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @activitiesStat.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activitiesStat;

  /// No description provided for @focusTimeDiaryStat.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTimeDiaryStat;

  /// No description provided for @pagesReadDiaryStat.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pagesReadDiaryStat;

  /// No description provided for @longestStat.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get longestStat;

  /// No description provided for @puppyCareGuide.
  ///
  /// In en, this message translates to:
  /// **'Buddy Care Guide'**
  String get puppyCareGuide;

  /// No description provided for @careUnder15.
  ///
  /// In en, this message translates to:
  /// **'Under 15 min'**
  String get careUnder15;

  /// No description provided for @care15to29.
  ///
  /// In en, this message translates to:
  /// **'15 - 29 min'**
  String get care15to29;

  /// No description provided for @care30to59.
  ///
  /// In en, this message translates to:
  /// **'30 - 59 min'**
  String get care30to59;

  /// No description provided for @care60plus.
  ///
  /// In en, this message translates to:
  /// **'60+ min'**
  String get care60plus;

  /// No description provided for @noCareYet.
  ///
  /// In en, this message translates to:
  /// **'No activities yet. Start a focus session to care for your buddy!'**
  String get noCareYet;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @league.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get league;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @viewLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'View Leaderboard'**
  String get viewLeaderboard;

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourRank;

  /// No description provided for @weeklyLeague.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get weeklyLeague;

  /// No description provided for @promotionZone.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotionZone;

  /// No description provided for @relegationZone.
  ///
  /// In en, this message translates to:
  /// **'Relegation'**
  String get relegationZone;

  /// No description provided for @safeZone.
  ///
  /// In en, this message translates to:
  /// **'Safe Zone'**
  String get safeZone;

  /// No description provided for @joinedLeague.
  ///
  /// In en, this message translates to:
  /// **'Joined league!'**
  String get joinedLeague;

  /// No description provided for @noLeagueYet.
  ///
  /// In en, this message translates to:
  /// **'No league yet'**
  String get noLeagueYet;

  /// No description provided for @rankLabel.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String rankLabel(int rank);

  /// No description provided for @friendsReading.
  ///
  /// In en, this message translates to:
  /// **'Friends Are Reading'**
  String get friendsReading;

  /// No description provided for @friendsReadingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add friends to see what they\'re reading!'**
  String get friendsReadingEmpty;

  /// No description provided for @pageProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} pages'**
  String pageProgress(int current, int total);

  /// No description provided for @companionDetail.
  ///
  /// In en, this message translates to:
  /// **'Companion'**
  String get companionDetail;

  /// No description provided for @evolutionStage.
  ///
  /// In en, this message translates to:
  /// **'Evolution Stage'**
  String get evolutionStage;

  /// No description provided for @xpProgress.
  ///
  /// In en, this message translates to:
  /// **'XP Progress'**
  String get xpProgress;

  /// No description provided for @xpToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to next level'**
  String xpToNextLevel(int xp);

  /// No description provided for @maxLevel.
  ///
  /// In en, this message translates to:
  /// **'Max Level Reached!'**
  String get maxLevel;

  /// No description provided for @evolutionRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Evolution Roadmap'**
  String get evolutionRoadmap;

  /// No description provided for @currentStage.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentStage;

  /// No description provided for @stagePuppy.
  ///
  /// In en, this message translates to:
  /// **'Puppy'**
  String get stagePuppy;

  /// No description provided for @stagePuppyRange.
  ///
  /// In en, this message translates to:
  /// **'Level 1 - 10'**
  String get stagePuppyRange;

  /// No description provided for @stageYoung.
  ///
  /// In en, this message translates to:
  /// **'Young Dog'**
  String get stageYoung;

  /// No description provided for @stageYoungRange.
  ///
  /// In en, this message translates to:
  /// **'Level 11 - 25'**
  String get stageYoungRange;

  /// No description provided for @stageAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult Dog'**
  String get stageAdult;

  /// No description provided for @stageAdultRange.
  ///
  /// In en, this message translates to:
  /// **'Level 26 - 40'**
  String get stageAdultRange;

  /// No description provided for @stageLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get stageLegendary;

  /// No description provided for @stageLegendaryRange.
  ///
  /// In en, this message translates to:
  /// **'Level 41 - 50'**
  String get stageLegendaryRange;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodHappyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your buddy is wagging its tail! Great job reading today!'**
  String get moodHappyDesc;

  /// No description provided for @moodHappyReason.
  ///
  /// In en, this message translates to:
  /// **'You read today! Great job!'**
  String get moodHappyReason;

  /// No description provided for @moodSleepy.
  ///
  /// In en, this message translates to:
  /// **'Sleepy'**
  String get moodSleepy;

  /// No description provided for @moodSleepyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your buddy is still snoozing... Morning reading would be a great start!'**
  String get moodSleepyDesc;

  /// No description provided for @moodSleepyReason.
  ///
  /// In en, this message translates to:
  /// **'Still waking up, waiting for you'**
  String get moodSleepyReason;

  /// No description provided for @moodCurious.
  ///
  /// In en, this message translates to:
  /// **'Curious'**
  String get moodCurious;

  /// No description provided for @moodCuriousDesc.
  ///
  /// In en, this message translates to:
  /// **'Your buddy is sniffing around wondering when you\'ll start reading!'**
  String get moodCuriousDesc;

  /// No description provided for @moodCuriousReason.
  ///
  /// In en, this message translates to:
  /// **'Wondering when you\'ll start reading'**
  String get moodCuriousReason;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodSadDesc.
  ///
  /// In en, this message translates to:
  /// **'Your buddy is getting worried... The evening is passing without reading!'**
  String get moodSadDesc;

  /// No description provided for @moodSadReason.
  ///
  /// In en, this message translates to:
  /// **'Evening came and no reading yet'**
  String get moodSadReason;

  /// No description provided for @moodAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get moodAngry;

  /// No description provided for @moodAngryDesc.
  ///
  /// In en, this message translates to:
  /// **'Your buddy is upset! It\'s almost midnight and you still haven\'t read!'**
  String get moodAngryDesc;

  /// No description provided for @moodAngryReason.
  ///
  /// In en, this message translates to:
  /// **'No reading before bedtime!'**
  String get moodAngryReason;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Reading Goal'**
  String get dailyGoal;

  /// No description provided for @dailyGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pages per day'**
  String get dailyGoalSubtitle;

  /// No description provided for @dailyGoalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Daily goal updated!'**
  String get dailyGoalUpdated;

  /// No description provided for @pagesPerDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pages/day'**
  String pagesPerDayCount(int count);

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @readingReminder.
  ///
  /// In en, this message translates to:
  /// **'READING REMINDER'**
  String get readingReminder;

  /// No description provided for @weekdayReminder.
  ///
  /// In en, this message translates to:
  /// **'Weekday Reminder'**
  String get weekdayReminder;

  /// No description provided for @weekendReminder.
  ///
  /// In en, this message translates to:
  /// **'Weekend Reminder'**
  String get weekendReminder;

  /// No description provided for @readingGoalDuration.
  ///
  /// In en, this message translates to:
  /// **'Reading Goal'**
  String get readingGoalDuration;

  /// No description provided for @reminderInfo.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you 10 minutes before your reading time'**
  String get reminderInfo;

  /// No description provided for @smartAlerts.
  ///
  /// In en, this message translates to:
  /// **'SMART ALERTS'**
  String get smartAlerts;

  /// No description provided for @streakRiskAlert.
  ///
  /// In en, this message translates to:
  /// **'Streak Risk Alert'**
  String get streakRiskAlert;

  /// No description provided for @streakRiskAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified at 20:00 if you haven\'t read today'**
  String get streakRiskAlertDesc;

  /// No description provided for @challengeNotificationsToggle.
  ///
  /// In en, this message translates to:
  /// **'Challenge Notifications'**
  String get challengeNotificationsToggle;

  /// No description provided for @challengeNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get reminders for challenges you\'ve joined'**
  String get challengeNotificationsDesc;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get quietHours;

  /// No description provided for @quietHoursDesc.
  ///
  /// In en, this message translates to:
  /// **'No notifications between 23:00 - 07:00'**
  String get quietHoursDesc;

  /// No description provided for @minutesDuration.
  ///
  /// In en, this message translates to:
  /// **'{min} minutes'**
  String minutesDuration(int min);

  /// No description provided for @notificationsDisabledDesc.
  ///
  /// In en, this message translates to:
  /// **'All notifications are turned off'**
  String get notificationsDisabledDesc;

  /// No description provided for @saveNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveNotificationSettings;

  /// No description provided for @readingReminderNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to read!'**
  String get readingReminderNotifTitle;

  /// No description provided for @readingReminderNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Your reading session starts soon. You got this!'**
  String get readingReminderNotifBody;

  /// No description provided for @bookFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'You finished a book!'**
  String get bookFinishedTitle;

  /// No description provided for @bookFinishedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! That\'s an amazing achievement.'**
  String get bookFinishedSubtitle;

  /// No description provided for @bookFinishedXpEarned.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP earned'**
  String bookFinishedXpEarned(int xp);

  /// No description provided for @bookFinishedDismiss.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get bookFinishedDismiss;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @activeChallenges.
  ///
  /// In en, this message translates to:
  /// **'Active Challenges'**
  String get activeChallenges;

  /// No description provided for @noChallengesYet.
  ///
  /// In en, this message translates to:
  /// **'No active challenges'**
  String get noChallengesYet;

  /// No description provided for @createChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create Challenge'**
  String get createChallenge;

  /// No description provided for @joinChallenge.
  ///
  /// In en, this message translates to:
  /// **'Join Challenge'**
  String get joinChallenge;

  /// No description provided for @leaveChallenge.
  ///
  /// In en, this message translates to:
  /// **'Leave Challenge'**
  String get leaveChallenge;

  /// No description provided for @challengeFull.
  ///
  /// In en, this message translates to:
  /// **'Challenge Full'**
  String get challengeFull;

  /// No description provided for @challengeJoined.
  ///
  /// In en, this message translates to:
  /// **'Challenge joined!'**
  String get challengeJoined;

  /// No description provided for @challengeLeft.
  ///
  /// In en, this message translates to:
  /// **'Challenge left!'**
  String get challengeLeft;

  /// No description provided for @challengeCreated.
  ///
  /// In en, this message translates to:
  /// **'Challenge created!'**
  String get challengeCreated;

  /// No description provided for @challengeTypeReadAlong.
  ///
  /// In en, this message translates to:
  /// **'Read-Along'**
  String get challengeTypeReadAlong;

  /// No description provided for @challengeTypeSprint.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get challengeTypeSprint;

  /// No description provided for @challengeTypeGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get challengeTypeGenre;

  /// No description provided for @challengeTypePages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get challengeTypePages;

  /// No description provided for @participantsCount.
  ///
  /// In en, this message translates to:
  /// **'Participants ({count}/{max})'**
  String participantsCount(int count, int max);

  /// No description provided for @challengeEndsIn.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String challengeEndsIn(int days);

  /// No description provided for @challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get challengeTitle;

  /// No description provided for @challengeDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get challengeDescription;

  /// No description provided for @challengeType.
  ///
  /// In en, this message translates to:
  /// **'Challenge Type'**
  String get challengeType;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @targetPages.
  ///
  /// In en, this message translates to:
  /// **'Target Pages'**
  String get targetPages;

  /// No description provided for @targetBooks.
  ///
  /// In en, this message translates to:
  /// **'Target Books'**
  String get targetBooks;

  /// No description provided for @targetMinutes.
  ///
  /// In en, this message translates to:
  /// **'Target Minutes'**
  String get targetMinutes;

  /// No description provided for @publicChallenge.
  ///
  /// In en, this message translates to:
  /// **'Public Challenge'**
  String get publicChallenge;

  /// No description provided for @privateChallenge.
  ///
  /// In en, this message translates to:
  /// **'Private Challenge'**
  String get privateChallenge;

  /// No description provided for @maxParticipants.
  ///
  /// In en, this message translates to:
  /// **'Max Participants'**
  String get maxParticipants;

  /// No description provided for @bookwormRequired.
  ///
  /// In en, this message translates to:
  /// **'Bookworm subscription required'**
  String get bookwormRequired;

  /// No description provided for @challengeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Challenge limit reached for your plan'**
  String get challengeLimitReached;

  /// No description provided for @challengeTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekend Reading Sprint'**
  String get challengeTitleHint;

  /// No description provided for @challengeGoalType.
  ///
  /// In en, this message translates to:
  /// **'Goal Type'**
  String get challengeGoalType;

  /// No description provided for @challengeDailyPages.
  ///
  /// In en, this message translates to:
  /// **'Daily Pages'**
  String get challengeDailyPages;

  /// No description provided for @challengeDailyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Daily Minutes'**
  String get challengeDailyMinutes;

  /// No description provided for @challengeDailyPagesTarget.
  ///
  /// In en, this message translates to:
  /// **'Pages per day'**
  String get challengeDailyPagesTarget;

  /// No description provided for @challengeDailyMinutesTarget.
  ///
  /// In en, this message translates to:
  /// **'Minutes per day'**
  String get challengeDailyMinutesTarget;

  /// No description provided for @challengeDailyPagesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 30'**
  String get challengeDailyPagesHint;

  /// No description provided for @challengeDailyMinutesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 45'**
  String get challengeDailyMinutesHint;

  /// No description provided for @challengeVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get challengeVisibility;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @viewAllBadges.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAllBadges;

  /// No description provided for @noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'No badges yet. Keep reading!'**
  String get noBadgesYet;

  /// No description provided for @badgeCollection.
  ///
  /// In en, this message translates to:
  /// **'Badge Collection'**
  String get badgeCollection;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @categoryReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get categoryReading;

  /// No description provided for @categoryStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get categoryStreak;

  /// No description provided for @categoryFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get categoryFocus;

  /// No description provided for @categorySpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get categorySpecial;

  /// No description provided for @badgeEarnedOn.
  ///
  /// In en, this message translates to:
  /// **'Earned on {date}'**
  String badgeEarnedOn(String date);

  /// No description provided for @shareBadge.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareBadge;

  /// No description provided for @shareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Badge sharing coming soon!'**
  String get shareComingSoon;

  /// No description provided for @badgesProgress.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} badges'**
  String badgesProgress(int earned, int total);

  /// No description provided for @keepReadingToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Keep reading to unlock!'**
  String get keepReadingToUnlock;

  /// No description provided for @quickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStart;

  /// No description provided for @myChallenges.
  ///
  /// In en, this message translates to:
  /// **'My Challenges'**
  String get myChallenges;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @noChallengesJoined.
  ///
  /// In en, this message translates to:
  /// **'Join a challenge to start competing!'**
  String get noChallengesJoined;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @startChallenge.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startChallenge;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String daysLabel(int days);

  /// No description provided for @templateWeekendSprint.
  ///
  /// In en, this message translates to:
  /// **'Weekend Sprint'**
  String get templateWeekendSprint;

  /// No description provided for @templateWeekendSprintDesc.
  ///
  /// In en, this message translates to:
  /// **'Read 100 pages this weekend. Quick & intense!'**
  String get templateWeekendSprintDesc;

  /// No description provided for @templatePageTurner.
  ///
  /// In en, this message translates to:
  /// **'30-Day Page Turner'**
  String get templatePageTurner;

  /// No description provided for @templatePageTurnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Read 1,000 pages in 30 days. The ultimate test!'**
  String get templatePageTurnerDesc;

  /// No description provided for @templateGenreExplorer.
  ///
  /// In en, this message translates to:
  /// **'Genre Explorer'**
  String get templateGenreExplorer;

  /// No description provided for @templateGenreExplorerDesc.
  ///
  /// In en, this message translates to:
  /// **'Read 3 books from a new genre this month.'**
  String get templateGenreExplorerDesc;

  /// No description provided for @templateSpeedReader.
  ///
  /// In en, this message translates to:
  /// **'Speed Reader'**
  String get templateSpeedReader;

  /// No description provided for @templateSpeedReaderDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish 300 pages in just 7 days!'**
  String get templateSpeedReaderDesc;

  /// No description provided for @templateBookClub.
  ///
  /// In en, this message translates to:
  /// **'Book Club'**
  String get templateBookClub;

  /// No description provided for @templateBookClubDesc.
  ///
  /// In en, this message translates to:
  /// **'Read a book together with friends in 2 weeks.'**
  String get templateBookClubDesc;

  /// No description provided for @templateFocusMarathon.
  ///
  /// In en, this message translates to:
  /// **'Focus Marathon'**
  String get templateFocusMarathon;

  /// No description provided for @templateFocusMarathonDesc.
  ///
  /// In en, this message translates to:
  /// **'Log 500 minutes of focus time in 2 weeks.'**
  String get templateFocusMarathonDesc;

  /// No description provided for @challengeStarted.
  ///
  /// In en, this message translates to:
  /// **'Challenge started! Good luck!'**
  String get challengeStarted;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @createCustomChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Challenge'**
  String get createCustomChallenge;

  /// No description provided for @editTotalPages.
  ///
  /// In en, this message translates to:
  /// **'Edit Total Pages'**
  String get editTotalPages;

  /// No description provided for @totalPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total pages'**
  String get totalPagesLabel;

  /// No description provided for @totalPagesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Total pages updated!'**
  String get totalPagesUpdated;

  /// No description provided for @continuingFromPage.
  ///
  /// In en, this message translates to:
  /// **'Continuing from page {page}'**
  String continuingFromPage(int page);

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @guideXpTitle.
  ///
  /// In en, this message translates to:
  /// **'XP System'**
  String get guideXpTitle;

  /// No description provided for @guideXpContent.
  ///
  /// In en, this message translates to:
  /// **'Earn XP (experience points) through reading activities:\n\n+10 XP per page read\n+50 XP daily reading goal completed\n+200 XP book finished\n+100 XP ReadBrain quiz completed (70%+ score)\n+25 XP daily streak maintained\n\nFocus Mode XP:\n+15 XP for 15 min session\n+30 XP for 30 min session\n+50 XP for 60+ min session\n\nChallenge XP:\n+50 XP join a challenge\n+150 XP complete a challenge\n+300 XP finish in Top 3\n\nMultipliers:\nx1.5 XP with 7+ day streak\nx2.0 XP on Double XP Day (surprise, 1 random day per week)'**
  String get guideXpContent;

  /// No description provided for @guideStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak System'**
  String get guideStreakTitle;

  /// No description provided for @guideStreakContent.
  ///
  /// In en, this message translates to:
  /// **'Maintain your reading streak by reading every day:\n\nRead at least 1 page or run the timer for 5 minutes to keep your streak alive.\n\nStreaks reset at midnight (UTC). Bookworm plan users get 1 Streak Freeze per week.\n\nStreak Milestones:\n7 days — On Fire badge\n30 days — Unstoppable badge\n100 days — Legend badge\n365 days — Immortal badge\n\nA 7+ day streak gives you a 1.5x XP multiplier on page reading!'**
  String get guideStreakContent;

  /// No description provided for @guideLeagueTitle.
  ///
  /// In en, this message translates to:
  /// **'League System'**
  String get guideLeagueTitle;

  /// No description provided for @guideLeagueContent.
  ///
  /// In en, this message translates to:
  /// **'Compete in weekly leagues with other readers:\n\nLeague Tiers:\nBronze → Silver → Gold → Platinum → Diamond\n\nYou\'re placed in a group of 30 readers at the same tier. Leagues run Monday to Sunday.\n\nPromotion & Relegation:\nTop 10 — Promoted to next tier\nBottom 5 — Relegated to lower tier\nMiddle — Stay in current tier\nDiamond league has no relegation.'**
  String get guideLeagueContent;

  /// No description provided for @guideCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'Paige — Your Reading Buddy'**
  String get guideCompanionTitle;

  /// No description provided for @guideCompanionContent.
  ///
  /// In en, this message translates to:
  /// **'Your reading buddy grows with you!\n\nGrowth Stages:\nLv 1-10 — Tiny Pup\nLv 11-25 — Playful Pup\nLv 26-40 — Growing Dog\nLv 41-50 — Majestic Dog\n\nEvery 500 XP = 1 level. Max level takes about 6 months of regular reading.\n\nBuddy Mood:\nRead daily — Happy, wagging tail\n1-2 days break — Slightly sulky\n3-4 days break — Turns back, messy fur\n5+ days break — Wrapped in blanket, sleeping\n\nDon\'t worry — your buddy always forgives you when you return!'**
  String get guideCompanionContent;

  /// No description provided for @guideBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Badge System'**
  String get guideBadgeTitle;

  /// No description provided for @guideBadgeContent.
  ///
  /// In en, this message translates to:
  /// **'Earn badges for reading achievements:\n\nReading Badges:\nFirst Page — Read your first page\nBookworm — Finish 10 books\nCentury Club — Finish 100 books\nSpeed Reader — Finish a book in under 3 days\nGenre Explorer — Read 5 different genres\n\nStreak Badges:\nOn Fire (7 days), Unstoppable (30 days), Legend (100 days), Immortal (365 days)\n\nSpecial Badges:\nReadBrain Certified — Quiz score 70%+\nDiamond League — Reach Diamond tier\nPaige\'s Best Friend — Buddy reaches Lv 25\nTop Dog — Buddy reaches Lv 50\n\nAll badges can be shared as BookTok/Instagram-ready cards!'**
  String get guideBadgeContent;

  /// No description provided for @guideFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get guideFocusTitle;

  /// No description provided for @guideFocusContent.
  ///
  /// In en, this message translates to:
  /// **'Stay focused while reading with our timer!\n\nModes:\nFree Timer — Open-ended reading session\nPomodoro — 25 min reading + 5 min break\nGoal-based — Read until you reach X pages\n\nBuddy Care Rewards:\nUnder 15 min — Snack\n15-29 min — Walk\n30-59 min — Play\n60+ min — Feast\n\nYour screen stays on during focus sessions so you can track your reading time easily.'**
  String get guideFocusContent;

  /// No description provided for @guideChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get guideChallengeTitle;

  /// No description provided for @guideChallengeContent.
  ///
  /// In en, this message translates to:
  /// **'Compete with other readers in timed challenges!\n\nChallenge Types:\nRead-Along — Read the same book together\nSprint — Who reads the most pages this week?\nGenre — Finish 3 sci-fi books this month\nPages Goal — Read 1,000 pages in 30 days\n\nEach challenge has up to 30 participants with a live leaderboard.\n\nXP Rewards:\n+50 XP for joining\n+150 XP for completing\n+300 XP for finishing in Top 3\n\nYou\'ll get smart reminders before challenges end and at the halfway point.\n\nYou can turn challenge notifications on or off in Notification Settings.'**
  String get guideChallengeContent;

  /// No description provided for @guideReadBrainTitle.
  ///
  /// In en, this message translates to:
  /// **'ReadBrain AI Quiz'**
  String get guideReadBrainTitle;

  /// No description provided for @guideReadBrainContent.
  ///
  /// In en, this message translates to:
  /// **'Test your understanding after finishing a book!\n\nAI generates 5 multiple-choice questions based on the book you\'ve read. Each question has 4 options with a brief explanation.\n\nScore 70% or higher to earn the ReadBrain Certified badge and +100 XP.\n\nYou get 3 attempts per book, then a 24-hour cooldown.\n\nPowered by Gemini AI — questions are unique and tailored to each book.'**
  String get guideReadBrainContent;

  /// No description provided for @guideAiScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Book Scanner'**
  String get guideAiScannerTitle;

  /// No description provided for @guideAiScannerContent.
  ///
  /// In en, this message translates to:
  /// **'Add books instantly by scanning the cover with your camera!\n\nJust tap the camera icon on the Add Book screen, take a photo of any book cover, and AI will automatically extract the title, author, and page count.\n\nPowered by Gemini AI with Groq as a smart fallback — works even when one service is temporarily unavailable.'**
  String get guideAiScannerContent;

  /// No description provided for @guideCalmModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Calm Mode'**
  String get guideCalmModeTitle;

  /// No description provided for @guideCalmModeContent.
  ///
  /// In en, this message translates to:
  /// **'Want to read without the pressure of XP, streaks, and competition?\n\nCalm Mode lets you track your reading in peace. While active:\n\n• Reading won\'t earn XP\n• Your streak won\'t update\n• Leagues and challenges are paused\n• You\'ll be removed from active challenges\n\nYour reading data is still tracked — you just won\'t see gamification elements. Toggle it anytime from your profile.\n\nPerfect for vacation reading or when you just want to enjoy a book without thinking about stats.'**
  String get guideCalmModeContent;

  /// No description provided for @challengeLastDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge ends tomorrow!'**
  String get challengeLastDayTitle;

  /// No description provided for @challengeLastDayBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" ends tomorrow. Keep reading to climb the ranks!'**
  String challengeLastDayBody(String title);

  /// No description provided for @challengeMidPointTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge halfway check-in'**
  String get challengeMidPointTitle;

  /// No description provided for @challengeMidPointBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re halfway through \"{title}\". How\'s your progress?'**
  String challengeMidPointBody(String title);

  /// No description provided for @challengeLastDayPageBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" ends tomorrow. You have {target} pages to go — you can do it!'**
  String challengeLastDayPageBody(String title, int target);

  /// No description provided for @challengeLastDaySprintBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" ends tomorrow. Every minute counts — start a focus session!'**
  String challengeLastDaySprintBody(String title);

  /// No description provided for @challengeLastDayGenreBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" ends tomorrow. Finish a book to boost your score!'**
  String challengeLastDayGenreBody(String title);

  /// No description provided for @challengeMidPointPageBody.
  ///
  /// In en, this message translates to:
  /// **'Halfway through \"{title}\"! Target: {target} pages. Keep the pace!'**
  String challengeMidPointPageBody(String title, int target);

  /// No description provided for @challengeMidPointSprintBody.
  ///
  /// In en, this message translates to:
  /// **'Halfway through \"{title}\"! Target: {target} minutes. Start a focus session!'**
  String challengeMidPointSprintBody(String title, int target);

  /// No description provided for @challengeMidPointGenreBody.
  ///
  /// In en, this message translates to:
  /// **'Halfway through \"{title}\"! Target: {target} books. How many have you finished?'**
  String challengeMidPointGenreBody(String title, int target);

  /// No description provided for @freeMode.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeMode;

  /// No description provided for @pomodoroMode.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoroMode;

  /// No description provided for @workPhase.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workPhase;

  /// No description provided for @breakPhase.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakPhase;

  /// No description provided for @pomodoroRound.
  ///
  /// In en, this message translates to:
  /// **'{count}. Pomodoro'**
  String pomodoroRound(int count);

  /// No description provided for @pomodoroInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'What is Pomodoro?'**
  String get pomodoroInfoTitle;

  /// No description provided for @pomodoroInfoBody.
  ///
  /// In en, this message translates to:
  /// **'The Pomodoro Technique helps you stay focused. Read for 25 minutes, then take a 5-minute break. The cycle repeats until you stop.'**
  String get pomodoroInfoBody;

  /// No description provided for @leagueInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'How Leagues Work'**
  String get leagueInfoTitle;

  /// No description provided for @leagueInfoHowXp.
  ///
  /// In en, this message translates to:
  /// **'How to Earn XP'**
  String get leagueInfoHowXp;

  /// No description provided for @leagueInfoHowXpContent.
  ///
  /// In en, this message translates to:
  /// **'Every reading activity earns XP that counts toward your league ranking:\n\n📖  +10 XP per page read\n⏱  +15–50 XP per focus session\n✅  +50 XP daily goal completed\n📚  +200 XP book finished\n🔥  +25 XP streak maintained'**
  String get leagueInfoHowXpContent;

  /// No description provided for @leagueInfoTiers.
  ///
  /// In en, this message translates to:
  /// **'League Tiers'**
  String get leagueInfoTiers;

  /// No description provided for @leagueInfoTiersContent.
  ///
  /// In en, this message translates to:
  /// **'🥉 Bronze → 🥈 Silver → 🥇 Gold → 💎 Platinum → 👑 Diamond'**
  String get leagueInfoTiersContent;

  /// No description provided for @leagueInfoRules.
  ///
  /// In en, this message translates to:
  /// **'Weekly Rules'**
  String get leagueInfoRules;

  /// No description provided for @leagueInfoRulesContent.
  ///
  /// In en, this message translates to:
  /// **'• 30 readers per group, same tier\n• Leagues run Monday to Sunday\n• Top 10 → Promoted to next tier\n• Bottom 5 → Relegated to lower tier\n• Diamond league has no relegation'**
  String get leagueInfoRulesContent;

  /// No description provided for @leagueInfoTip.
  ///
  /// In en, this message translates to:
  /// **'Read every day to climb the leaderboard!'**
  String get leagueInfoTip;

  /// No description provided for @leagueWeekDay.
  ///
  /// In en, this message translates to:
  /// **'Weekly League Day {day}/7'**
  String leagueWeekDay(int day);

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @searchFriends.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get searchFriends;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'{count} Pending Requests'**
  String pendingRequests(int count);

  /// No description provided for @friendsCount.
  ///
  /// In en, this message translates to:
  /// **'Friends ({count})'**
  String friendsCount(int count);

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYet;

  /// No description provided for @searchToAddFriends.
  ///
  /// In en, this message translates to:
  /// **'Search by name to add friends'**
  String get searchToAddFriends;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addFriend;

  /// No description provided for @wantsToBeYourFriend.
  ///
  /// In en, this message translates to:
  /// **'Wants to be your friend'**
  String get wantsToBeYourFriend;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @removeFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove Friend'**
  String get removeFriend;

  /// No description provided for @removeFriendConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your friends?'**
  String removeFriendConfirm(String name);

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent!'**
  String get requestSent;

  /// No description provided for @friendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted!'**
  String get friendRequestAccepted;

  /// No description provided for @yourId.
  ///
  /// In en, this message translates to:
  /// **'Your ID: {id}'**
  String yourId(String id);

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share your profile so friends can find you!'**
  String get shareProfile;

  /// No description provided for @shareProfileText.
  ///
  /// In en, this message translates to:
  /// **'Add me on Bookpulse! My name: {name} (#{id})'**
  String shareProfileText(String name, String id);

  /// No description provided for @alreadyFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get alreadyFriends;

  /// No description provided for @pendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingRequest;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @challengeInviteFrom.
  ///
  /// In en, this message translates to:
  /// **'Challenge invite from {name}'**
  String challengeInviteFrom(String name);

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent!'**
  String get inviteSent;

  /// No description provided for @selectFriendsToInvite.
  ///
  /// In en, this message translates to:
  /// **'Select friends to invite'**
  String get selectFriendsToInvite;

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from Library'**
  String get removeFromLibrary;

  /// No description provided for @removeBookConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Book'**
  String get removeBookConfirmTitle;

  /// No description provided for @removeBookConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this book from your library? Your reading progress will be lost.'**
  String get removeBookConfirmMessage;

  /// No description provided for @bookRemoved.
  ///
  /// In en, this message translates to:
  /// **'Book removed from library'**
  String get bookRemoved;

  /// No description provided for @readingJourney.
  ///
  /// In en, this message translates to:
  /// **'Reading Journey'**
  String get readingJourney;

  /// No description provided for @journeyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey starts here'**
  String get journeyEmptyTitle;

  /// No description provided for @journeyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a focus session or log pages to see your reading path grow!'**
  String get journeyEmptySubtitle;

  /// No description provided for @journeyFocusSession.
  ///
  /// In en, this message translates to:
  /// **'Focus Session'**
  String get journeyFocusSession;

  /// No description provided for @journeyPageProgress.
  ///
  /// In en, this message translates to:
  /// **'Pages Read'**
  String get journeyPageProgress;

  /// No description provided for @journeyBookFinished.
  ///
  /// In en, this message translates to:
  /// **'Book Finished'**
  String get journeyBookFinished;

  /// No description provided for @journeyBadgeEarned.
  ///
  /// In en, this message translates to:
  /// **'Badge Earned'**
  String get journeyBadgeEarned;

  /// No description provided for @journeyStreakMilestone.
  ///
  /// In en, this message translates to:
  /// **'Streak Milestone'**
  String get journeyStreakMilestone;

  /// No description provided for @journeyChallengeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Challenge Done'**
  String get journeyChallengeCompleted;

  /// No description provided for @journeyLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Level Up'**
  String get journeyLevelUp;

  /// No description provided for @journeyFocusMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min session'**
  String journeyFocusMinutes(int minutes);

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get pages;

  /// No description provided for @journeyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue Journey'**
  String get journeyContinue;

  /// No description provided for @journeyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get journeyToday;

  /// No description provided for @journeyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get journeyYesterday;

  /// No description provided for @journeyMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get journeyMin;

  /// No description provided for @homeChallengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Challenges'**
  String get homeChallengesTitle;

  /// No description provided for @homeNoChallenges.
  ///
  /// In en, this message translates to:
  /// **'No active challenges'**
  String get homeNoChallenges;

  /// No description provided for @homeJoinChallenge.
  ///
  /// In en, this message translates to:
  /// **'Discover Challenges'**
  String get homeJoinChallenge;

  /// No description provided for @homeChallengeOf.
  ///
  /// In en, this message translates to:
  /// **'{current}/{target}'**
  String homeChallengeOf(int current, int target);

  /// No description provided for @scanPages.
  ///
  /// In en, this message translates to:
  /// **'Scan Pages'**
  String get scanPages;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from Gallery'**
  String get pickFromGallery;

  /// No description provided for @scanProcessing.
  ///
  /// In en, this message translates to:
  /// **'Recognizing text...'**
  String get scanProcessing;

  /// No description provided for @scanStartOcr.
  ///
  /// In en, this message translates to:
  /// **'Recognize Text'**
  String get scanStartOcr;

  /// No description provided for @scanPageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String scanPageNumber(int number);

  /// No description provided for @scanPageUnknown.
  ///
  /// In en, this message translates to:
  /// **'Page (Unknown)'**
  String get scanPageUnknown;

  /// No description provided for @scanPagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} pages scanned'**
  String scanPagesCount(int count, int max);

  /// No description provided for @scanMore.
  ///
  /// In en, this message translates to:
  /// **'Scan More'**
  String get scanMore;

  /// No description provided for @scanDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get scanDone;

  /// No description provided for @scanNoText.
  ///
  /// In en, this message translates to:
  /// **'No text detected in this image'**
  String get scanNoText;

  /// No description provided for @scanMaxReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} pages allowed'**
  String scanMaxReached(int max);

  /// No description provided for @scanningPage.
  ///
  /// In en, this message translates to:
  /// **'Scanning page...'**
  String get scanningPage;

  /// No description provided for @pagesSaved.
  ///
  /// In en, this message translates to:
  /// **'Pages saved successfully!'**
  String get pagesSaved;

  /// No description provided for @savingPages.
  ///
  /// In en, this message translates to:
  /// **'Saving pages...'**
  String get savingPages;

  /// No description provided for @streakDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Streak'**
  String get streakDetailTitle;

  /// No description provided for @streakDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get streakDaysLabel;

  /// No description provided for @streakBonusActive.
  ///
  /// In en, this message translates to:
  /// **'1.5x XP Streak Bonus Active!'**
  String get streakBonusActive;

  /// No description provided for @streakTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get streakTodayTitle;

  /// No description provided for @streakPagesRemaining.
  ///
  /// In en, this message translates to:
  /// **'Read {count} more pages to reach your daily goal and keep your streak!'**
  String streakPagesRemaining(int count);

  /// No description provided for @streakHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How Streaks Work'**
  String get streakHowItWorks;

  /// No description provided for @streakRule1.
  ///
  /// In en, this message translates to:
  /// **'Complete your daily reading goal every day to keep your streak alive.'**
  String get streakRule1;

  /// No description provided for @streakRule2.
  ///
  /// In en, this message translates to:
  /// **'Your streak resets at midnight (UTC) if you haven\'t reached your goal. Don\'t miss a day!'**
  String get streakRule2;

  /// No description provided for @streakRule3.
  ///
  /// In en, this message translates to:
  /// **'Reach a 7-day streak to unlock a 1.5x XP bonus on all activities. You can change your daily goal from your profile.'**
  String get streakRule3;

  /// No description provided for @streakLast28Days.
  ///
  /// In en, this message translates to:
  /// **'Last 28 Days'**
  String get streakLast28Days;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tu'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Th'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fr'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get weekdaySun;

  /// No description provided for @streakNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No reading activity yet. Start reading to build your streak!'**
  String get streakNoHistory;

  /// No description provided for @streakRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get streakRecentActivity;

  /// No description provided for @streakToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get streakToday;

  /// No description provided for @streakYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get streakYesterday;

  /// No description provided for @streakDayPages.
  ///
  /// In en, this message translates to:
  /// **'{count} pages read'**
  String streakDayPages(int count);

  /// No description provided for @streakDayMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min reading'**
  String streakDayMinutes(int count);

  /// No description provided for @streakTodaySessions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reading'**
  String get streakTodaySessions;

  /// No description provided for @streakSessionDetail.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {pages} pages'**
  String streakSessionDetail(int minutes, int pages);

  /// No description provided for @readerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Your Reader Soul'**
  String get readerProfileTitle;

  /// No description provided for @readerProfileQ1.
  ///
  /// In en, this message translates to:
  /// **'What was the last book that truly moved you?'**
  String get readerProfileQ1;

  /// No description provided for @readerProfileQ1Hint.
  ///
  /// In en, this message translates to:
  /// **'Write the book title or what it was about...'**
  String get readerProfileQ1Hint;

  /// No description provided for @readerProfileQ2aTitle.
  ///
  /// In en, this message translates to:
  /// **'What moved you most in that book?'**
  String get readerProfileQ2aTitle;

  /// No description provided for @readerProfileQ2bTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you look for when reading?'**
  String get readerProfileQ2bTitle;

  /// No description provided for @readerProfileQ2cTitle.
  ///
  /// In en, this message translates to:
  /// **'What draws you in first?'**
  String get readerProfileQ2cTitle;

  /// No description provided for @readerProfileQ3Title.
  ///
  /// In en, this message translates to:
  /// **'One more question...'**
  String get readerProfileQ3Title;

  /// No description provided for @readerProfileAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your reading soul...'**
  String get readerProfileAnalyzing;

  /// No description provided for @readerProfileYourArchetype.
  ///
  /// In en, this message translates to:
  /// **'Your Reader Archetype'**
  String get readerProfileYourArchetype;

  /// No description provided for @readerProfileReadingDna.
  ///
  /// In en, this message translates to:
  /// **'Your Reading DNA'**
  String get readerProfileReadingDna;

  /// No description provided for @readerProfileRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get readerProfileRecommended;

  /// No description provided for @readerProfileLetsStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Start Reading!'**
  String get readerProfileLetsStart;

  /// No description provided for @readerProfileDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get readerProfileDone;

  /// No description provided for @readerProfileCharacterFocus.
  ///
  /// In en, this message translates to:
  /// **'Character Focus'**
  String get readerProfileCharacterFocus;

  /// No description provided for @readerProfilePlotFocus.
  ///
  /// In en, this message translates to:
  /// **'Plot Focus'**
  String get readerProfilePlotFocus;

  /// No description provided for @readerProfileAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Atmosphere'**
  String get readerProfileAtmosphere;

  /// No description provided for @readerProfilePace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get readerProfilePace;

  /// No description provided for @readerProfileDiscoverArchetype.
  ///
  /// In en, this message translates to:
  /// **'Discover Your Reader Archetype'**
  String get readerProfileDiscoverArchetype;

  /// No description provided for @readerProfileDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a quick quiz for personalized recommendations'**
  String get readerProfileDiscoverSubtitle;

  /// No description provided for @readerProfileUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get readerProfileUpdate;

  /// No description provided for @readerProfileRetakeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get readerProfileRetakeQuiz;

  /// No description provided for @readerProfilePreferredGenres.
  ///
  /// In en, this message translates to:
  /// **'Preferred Genres'**
  String get readerProfilePreferredGenres;

  /// No description provided for @readerProfileReadingTone.
  ///
  /// In en, this message translates to:
  /// **'Reading Tone'**
  String get readerProfileReadingTone;

  /// No description provided for @readerProfileAvoidGenres.
  ///
  /// In en, this message translates to:
  /// **'Avoided Genres'**
  String get readerProfileAvoidGenres;

  /// No description provided for @readerProfileRecommendedBooks.
  ///
  /// In en, this message translates to:
  /// **'Recommended Books'**
  String get readerProfileRecommendedBooks;

  /// No description provided for @readerProfileError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get readerProfileError;

  /// No description provided for @readerProfileRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get readerProfileRetry;

  /// No description provided for @readerProfileQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Reader Profile'**
  String get readerProfileQuizTitle;

  /// No description provided for @noProfileYet.
  ///
  /// In en, this message translates to:
  /// **'No reader profile yet. Take the quiz to discover your archetype!'**
  String get noProfileYet;

  /// No description provided for @chipCharactersAndPsychology.
  ///
  /// In en, this message translates to:
  /// **'Characters & Psychology'**
  String get chipCharactersAndPsychology;

  /// No description provided for @chipAtmosphereAndLanguage.
  ///
  /// In en, this message translates to:
  /// **'Atmosphere & Language'**
  String get chipAtmosphereAndLanguage;

  /// No description provided for @chipPlotAndSurprises.
  ///
  /// In en, this message translates to:
  /// **'Plot & Surprises'**
  String get chipPlotAndSurprises;

  /// No description provided for @chipThemesAndIdeas.
  ///
  /// In en, this message translates to:
  /// **'Themes & Ideas'**
  String get chipThemesAndIdeas;

  /// No description provided for @chipPracticalKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Practical Knowledge'**
  String get chipPracticalKnowledge;

  /// No description provided for @chipPerspectiveChange.
  ///
  /// In en, this message translates to:
  /// **'Perspective Change'**
  String get chipPerspectiveChange;

  /// No description provided for @chipInspirationMotivation.
  ///
  /// In en, this message translates to:
  /// **'Inspiration & Motivation'**
  String get chipInspirationMotivation;

  /// No description provided for @chipDeepAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Deep Analysis'**
  String get chipDeepAnalysis;

  /// No description provided for @chipWorldBuilding.
  ///
  /// In en, this message translates to:
  /// **'World Building & Universe'**
  String get chipWorldBuilding;

  /// No description provided for @chipCharactersRelationships.
  ///
  /// In en, this message translates to:
  /// **'Characters & Relationships'**
  String get chipCharactersRelationships;

  /// No description provided for @chipIdeasPhilosophy.
  ///
  /// In en, this message translates to:
  /// **'Ideas & Philosophy'**
  String get chipIdeasPhilosophy;

  /// No description provided for @chipActionAdventure.
  ///
  /// In en, this message translates to:
  /// **'Action & Adventure'**
  String get chipActionAdventure;

  /// No description provided for @chipInnerWorldMonologue.
  ///
  /// In en, this message translates to:
  /// **'Inner world & monologue'**
  String get chipInnerWorldMonologue;

  /// No description provided for @chipRelationshipTension.
  ///
  /// In en, this message translates to:
  /// **'Relationship tension'**
  String get chipRelationshipTension;

  /// No description provided for @chipSlowIntenseBeautiful.
  ///
  /// In en, this message translates to:
  /// **'Slow, intense, hauntingly beautiful'**
  String get chipSlowIntenseBeautiful;

  /// No description provided for @chipFastCinematic.
  ///
  /// In en, this message translates to:
  /// **'Fast but cinematic'**
  String get chipFastCinematic;

  /// No description provided for @chipUnpredictable.
  ///
  /// In en, this message translates to:
  /// **'Yes, keep me guessing'**
  String get chipUnpredictable;

  /// No description provided for @chipJourneyMatters.
  ///
  /// In en, this message translates to:
  /// **'No, the journey matters'**
  String get chipJourneyMatters;

  /// No description provided for @chipDisturbQuestion.
  ///
  /// In en, this message translates to:
  /// **'Disturb me, make me question'**
  String get chipDisturbQuestion;

  /// No description provided for @chipPeaceAndMeaning.
  ///
  /// In en, this message translates to:
  /// **'Give me peace and meaning'**
  String get chipPeaceAndMeaning;

  /// No description provided for @chipBusinessProductivity.
  ///
  /// In en, this message translates to:
  /// **'Business & Productivity'**
  String get chipBusinessProductivity;

  /// No description provided for @chipPsychologyRelationships.
  ///
  /// In en, this message translates to:
  /// **'Psychology & Relationships'**
  String get chipPsychologyRelationships;

  /// No description provided for @chipHabitsLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Habits & Lifestyle'**
  String get chipHabitsLifestyle;

  /// No description provided for @chipPhilosophicalExistential.
  ///
  /// In en, this message translates to:
  /// **'Philosophical & Existential'**
  String get chipPhilosophicalExistential;

  /// No description provided for @chipSocialPolitical.
  ///
  /// In en, this message translates to:
  /// **'Social & Political'**
  String get chipSocialPolitical;

  /// No description provided for @chipRealLifeStories.
  ///
  /// In en, this message translates to:
  /// **'Real life stories'**
  String get chipRealLifeStories;

  /// No description provided for @chipFictionalHeroes.
  ///
  /// In en, this message translates to:
  /// **'Fictional heroes'**
  String get chipFictionalHeroes;

  /// No description provided for @chipHistoryHumanNature.
  ///
  /// In en, this message translates to:
  /// **'History & Human Nature'**
  String get chipHistoryHumanNature;

  /// No description provided for @chipScienceFuture.
  ///
  /// In en, this message translates to:
  /// **'Science & Future'**
  String get chipScienceFuture;

  /// No description provided for @chipHardSfRealistic.
  ///
  /// In en, this message translates to:
  /// **'Hard SF, scientific realism'**
  String get chipHardSfRealistic;

  /// No description provided for @chipMythologicalMagical.
  ///
  /// In en, this message translates to:
  /// **'Mythological & magical'**
  String get chipMythologicalMagical;

  /// No description provided for @chipAntiheroDark.
  ///
  /// In en, this message translates to:
  /// **'Anti-hero, dark'**
  String get chipAntiheroDark;

  /// No description provided for @chipGrowthJourney.
  ///
  /// In en, this message translates to:
  /// **'Growth journey'**
  String get chipGrowthJourney;

  /// No description provided for @chipMindBendingTwists.
  ///
  /// In en, this message translates to:
  /// **'Mind-bending twists'**
  String get chipMindBendingTwists;

  /// No description provided for @chipDeepSadnessBeauty.
  ///
  /// In en, this message translates to:
  /// **'Deep sadness & beauty'**
  String get chipDeepSadnessBeauty;

  /// No description provided for @chipNonStopAction.
  ///
  /// In en, this message translates to:
  /// **'Non-stop action'**
  String get chipNonStopAction;

  /// No description provided for @chipActionPlusDepth.
  ///
  /// In en, this message translates to:
  /// **'Action + character depth'**
  String get chipActionPlusDepth;

  /// No description provided for @preferredGenresTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferred Genres'**
  String get preferredGenresTitle;

  /// No description provided for @readingToneTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Tone'**
  String get readingToneTitle;

  /// No description provided for @readingDnaTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Reading DNA'**
  String get readingDnaTitle;

  /// No description provided for @characterFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Character Focus'**
  String get characterFocusLabel;

  /// No description provided for @plotFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Plot Focus'**
  String get plotFocusLabel;

  /// No description provided for @atmosphereFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Atmosphere'**
  String get atmosphereFocusLabel;

  /// No description provided for @paceFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get paceFocusLabel;

  /// No description provided for @recommendedBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended Books'**
  String get recommendedBooksTitle;

  /// No description provided for @avoidedGenresTitle.
  ///
  /// In en, this message translates to:
  /// **'Avoided Genres'**
  String get avoidedGenresTitle;

  /// No description provided for @updateProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfileButton;

  /// No description provided for @bookActionRead.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Read'**
  String get bookActionRead;

  /// No description provided for @bookActionWillRead.
  ///
  /// In en, this message translates to:
  /// **'Will Read'**
  String get bookActionWillRead;

  /// No description provided for @bookMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'Added to finished'**
  String get bookMarkedAsRead;

  /// No description provided for @bookMarkedAsWillRead.
  ///
  /// In en, this message translates to:
  /// **'Added to reading list'**
  String get bookMarkedAsWillRead;

  /// No description provided for @loadMoreRecsButton.
  ///
  /// In en, this message translates to:
  /// **'Get More Recommendations'**
  String get loadMoreRecsButton;

  /// No description provided for @loadingMoreRecs.
  ///
  /// In en, this message translates to:
  /// **'Finding new books...'**
  String get loadingMoreRecs;

  /// No description provided for @bookActionNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Not for me'**
  String get bookActionNotInterested;

  /// No description provided for @bookMarkedAsNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get bookMarkedAsNotInterested;

  /// No description provided for @confirmYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get confirmYes;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get confirmCancel;

  /// No description provided for @confirmBookRead.
  ///
  /// In en, this message translates to:
  /// **'Add \"{bookTitle}\" to your finished books?'**
  String confirmBookRead(String bookTitle);

  /// No description provided for @confirmBookWillRead.
  ///
  /// In en, this message translates to:
  /// **'Add \"{bookTitle}\" to your reading list?'**
  String confirmBookWillRead(String bookTitle);

  /// No description provided for @confirmBookNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Mark \"{bookTitle}\" as not interested? Similar books won\'t be recommended.'**
  String confirmBookNotInterested(String bookTitle);

  /// No description provided for @challengeDetailYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get challengeDetailYourProgress;

  /// No description provided for @challengeDetailDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String challengeDetailDaysRemaining(int days);

  /// No description provided for @challengeDetailEndsToday.
  ///
  /// In en, this message translates to:
  /// **'Ends today'**
  String get challengeDetailEndsToday;

  /// No description provided for @challengeDetailEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get challengeDetailEnded;

  /// No description provided for @challengeDetailStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {days} days'**
  String challengeDetailStartsIn(int days);

  /// No description provided for @challengeDetailProgressOf.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target}'**
  String challengeDetailProgressOf(int current, int target);

  /// No description provided for @challengeDetailLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get challengeDetailLeaderboard;

  /// No description provided for @challengeDetailYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get challengeDetailYou;

  /// No description provided for @challengeDetailNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Start reading to track your progress!'**
  String get challengeDetailNotStarted;

  /// No description provided for @challengeDetailCompleted.
  ///
  /// In en, this message translates to:
  /// **'Target reached!'**
  String get challengeDetailCompleted;

  /// No description provided for @challengeDetailPagesUnit.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get challengeDetailPagesUnit;

  /// No description provided for @challengeDetailMinutesUnit.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get challengeDetailMinutesUnit;

  /// No description provided for @challengeDetailBooksUnit.
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get challengeDetailBooksUnit;

  /// No description provided for @savingProgress.
  ///
  /// In en, this message translates to:
  /// **'Saving your progress...'**
  String get savingProgress;

  /// No description provided for @updatingCompetitionStatus.
  ///
  /// In en, this message translates to:
  /// **'Updating your league and challenge standings'**
  String get updatingCompetitionStatus;

  /// No description provided for @calmMode.
  ///
  /// In en, this message translates to:
  /// **'Calm Mode'**
  String get calmMode;

  /// No description provided for @calmModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track reading without XP, streaks, or leagues'**
  String get calmModeSubtitle;

  /// No description provided for @calmModeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Calm Mode?'**
  String get calmModeConfirmTitle;

  /// No description provided for @calmModeConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'In Calm Mode, your reading won\'t earn XP, update your streak, or count toward leagues and challenges. You\'ll be removed from any active challenges.\n\nYou can exit Calm Mode anytime from your profile.'**
  String get calmModeConfirmMessage;

  /// No description provided for @calmModeConfirmWithChallenges.
  ///
  /// In en, this message translates to:
  /// **'You have {count} active challenge(s). Enabling Calm Mode will remove you from all of them.'**
  String calmModeConfirmWithChallenges(int count);

  /// No description provided for @calmModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Calm Mode enabled'**
  String get calmModeEnabled;

  /// No description provided for @calmModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Calm Mode disabled'**
  String get calmModeDisabled;

  /// No description provided for @calmModeDisableTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Calm Mode?'**
  String get calmModeDisableTitle;

  /// No description provided for @calmModeDisableMessage.
  ///
  /// In en, this message translates to:
  /// **'Your reading will start earning XP again, your streak will be tracked, and league standings will update.\n\nReady to jump back in?'**
  String get calmModeDisableMessage;

  /// No description provided for @discoverCalmModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover is paused'**
  String get discoverCalmModeTitle;

  /// No description provided for @discoverCalmModeMessage.
  ///
  /// In en, this message translates to:
  /// **'Challenges are disabled in Calm Mode'**
  String get discoverCalmModeMessage;

  /// No description provided for @exitCalmMode.
  ///
  /// In en, this message translates to:
  /// **'Exit Calm Mode'**
  String get exitCalmMode;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @startReadingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Move \"{title}\" to your reading list and start reading?'**
  String startReadingConfirm(String title);

  /// No description provided for @movedToReading.
  ///
  /// In en, this message translates to:
  /// **'Moved to reading!'**
  String get movedToReading;

  /// No description provided for @tbrOrder.
  ///
  /// In en, this message translates to:
  /// **'#{order}'**
  String tbrOrder(int order);

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder your reading list'**
  String get dragToReorder;

  /// No description provided for @swipeToStartReading.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to start reading'**
  String get swipeToStartReading;

  /// No description provided for @scanBookCover.
  ///
  /// In en, this message translates to:
  /// **'Scan Book Cover'**
  String get scanBookCover;

  /// No description provided for @scanningBookCover.
  ///
  /// In en, this message translates to:
  /// **'Analyzing book cover...'**
  String get scanningBookCover;

  /// No description provided for @scanningBookCoverDesc.
  ///
  /// In en, this message translates to:
  /// **'AI is reading the cover, hang tight!'**
  String get scanningBookCoverDesc;

  /// No description provided for @bookCoverNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Book not detected. Please check and try again.'**
  String get bookCoverNotDetected;

  /// No description provided for @bookCoverScanError.
  ///
  /// In en, this message translates to:
  /// **'Could not scan the book cover. Please try again.'**
  String get bookCoverScanError;

  /// No description provided for @addCoverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Cover Photo (Optional)'**
  String get addCoverPhoto;

  /// No description provided for @coverPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Cover photo added'**
  String get coverPhotoAdded;

  /// No description provided for @tapToChangeCover.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChangeCover;

  /// No description provided for @changeCoverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Cover Photo'**
  String get changeCoverPhoto;

  /// No description provided for @removeCustomCover.
  ///
  /// In en, this message translates to:
  /// **'Remove Custom Cover'**
  String get removeCustomCover;

  /// No description provided for @coverPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cover photo updated!'**
  String get coverPhotoUpdated;

  /// No description provided for @coverPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update cover photo. Please try again.'**
  String get coverPhotoError;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @bookNotes.
  ///
  /// In en, this message translates to:
  /// **'Book Notes'**
  String get bookNotes;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @takePagePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Page Photo'**
  String get takePagePhoto;

  /// No description provided for @pickPagePhoto.
  ///
  /// In en, this message translates to:
  /// **'Pick Page Photo'**
  String get pickPagePhoto;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get fromGallery;

  /// No description provided for @savingNote.
  ///
  /// In en, this message translates to:
  /// **'Saving note...'**
  String get savingNote;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @noNotesDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap above to add a note or take a page photo'**
  String get noNotesDescription;

  /// No description provided for @pageNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Page number (optional)'**
  String get pageNumberOptional;

  /// No description provided for @writeYourNote.
  ///
  /// In en, this message translates to:
  /// **'Write your note...'**
  String get writeYourNote;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get saveNote;

  /// No description provided for @addNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get addNoteOptional;

  /// No description provided for @openCamera.
  ///
  /// In en, this message translates to:
  /// **'Open Camera'**
  String get openCamera;

  /// No description provided for @openGallery.
  ///
  /// In en, this message translates to:
  /// **'Open Gallery'**
  String get openGallery;

  /// No description provided for @pageN.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageN(int page);

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteNoteConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get myNotes;

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String notesCount(int count);

  /// No description provided for @noNotesForBook.
  ///
  /// In en, this message translates to:
  /// **'No notes for this book yet'**
  String get noNotesForBook;

  /// No description provided for @noNotesForBookDesc.
  ///
  /// In en, this message translates to:
  /// **'Start a focus session and take notes while reading'**
  String get noNotesForBookDesc;

  /// No description provided for @deleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteActivity;

  /// No description provided for @deleteActivityConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry from your reading journey?'**
  String get deleteActivityConfirm;

  /// No description provided for @notReadingAnything.
  ///
  /// In en, this message translates to:
  /// **'Not reading anything right now'**
  String get notReadingAnything;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @manageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage Tags'**
  String get manageTags;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'New Tag'**
  String get newTag;

  /// No description provided for @newTagHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tag name'**
  String get newTagHint;

  /// No description provided for @tagAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This tag already exists'**
  String get tagAlreadyExists;

  /// No description provided for @tagAdded.
  ///
  /// In en, this message translates to:
  /// **'Tag added'**
  String get tagAdded;

  /// No description provided for @tagsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Tags updated'**
  String get tagsUpdated;

  /// No description provided for @defaultTagFiction.
  ///
  /// In en, this message translates to:
  /// **'Fiction'**
  String get defaultTagFiction;

  /// No description provided for @defaultTagSelfHelp.
  ///
  /// In en, this message translates to:
  /// **'Self-Help'**
  String get defaultTagSelfHelp;

  /// No description provided for @defaultTagNonFiction.
  ///
  /// In en, this message translates to:
  /// **'Non-Fiction'**
  String get defaultTagNonFiction;

  /// No description provided for @defaultTagRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get defaultTagRomance;

  /// No description provided for @defaultTagMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get defaultTagMystery;

  /// No description provided for @filterByTag.
  ///
  /// In en, this message translates to:
  /// **'Filter by tag'**
  String get filterByTag;

  /// No description provided for @allBooks.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allBooks;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @noProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'No Progress Recorded'**
  String get noProgressTitle;

  /// No description provided for @noProgressBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the same page as when you started. No XP will be earned for this session.'**
  String get noProgressBody;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @endAnyway.
  ///
  /// In en, this message translates to:
  /// **'End Anyway'**
  String get endAnyway;

  /// No description provided for @dailyGoalNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break your streak!'**
  String get dailyGoalNotifTitle;

  /// No description provided for @dailyGoalNotifBody.
  ///
  /// In en, this message translates to:
  /// **'You still have {remaining} pages to go. A quick session is all it takes!'**
  String dailyGoalNotifBody(int remaining);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
