import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('bn'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DeenRoutine'**
  String get appTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @emailValidatorError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailValidatorError;

  /// No description provided for @passwordValidatorError.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get passwordValidatorError;

  /// No description provided for @requiredValidatorError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredValidatorError;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @registerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get registerPrompt;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @barakahCircleTitle.
  ///
  /// In en, this message translates to:
  /// **'Barakah Circle'**
  String get barakahCircleTitle;

  /// No description provided for @habitsDoneToday.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} habits done today'**
  String habitsDoneToday(Object done, Object total);

  /// No description provided for @todaysHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Habits'**
  String get todaysHabitsTitle;

  /// No description provided for @noHabitsYet.
  ///
  /// In en, this message translates to:
  /// **'No habits yet. Tap + to add your first one.'**
  String get noHabitsYet;

  /// No description provided for @prayerTimesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prayer times unavailable: {error}'**
  String prayerTimesUnavailable(Object error);

  /// No description provided for @prayerErrorLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get prayerErrorLocationDisabled;

  /// No description provided for @prayerErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get prayerErrorPermissionDenied;

  /// No description provided for @prayerErrorPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied.'**
  String get prayerErrorPermissionDeniedForever;

  /// No description provided for @prayerErrorFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch prayer times ({statusCode})'**
  String prayerErrorFetchFailed(Object statusCode);

  /// No description provided for @prayerErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading prayer times.'**
  String get prayerErrorUnknown;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @newHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'New Habit'**
  String get newHabitTitle;

  /// No description provided for @habitTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Habit title'**
  String get habitTitleLabel;

  /// No description provided for @habitTitleValidatorError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a habit title'**
  String get habitTitleValidatorError;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @frequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequencyLabel;

  /// No description provided for @repeatOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get repeatOnLabel;

  /// No description provided for @selectAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Select at least one day'**
  String get selectAtLeastOneDay;

  /// No description provided for @dailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminderTitle;

  /// No description provided for @reminderOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off — tap to set a time'**
  String get reminderOffSubtitle;

  /// No description provided for @reminderAtTime.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String reminderAtTime(Object time);

  /// No description provided for @saveHabitButton.
  ///
  /// In en, this message translates to:
  /// **'Save Habit'**
  String get saveHabitButton;

  /// No description provided for @categoryIslam.
  ///
  /// In en, this message translates to:
  /// **'Islam'**
  String get categoryIslam;

  /// No description provided for @categoryLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get categoryLifestyle;

  /// No description provided for @categoryLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get categoryLearn;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @frequencySpecificDays.
  ///
  /// In en, this message translates to:
  /// **'Specific days'**
  String get frequencySpecificDays;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @habitStreakDays.
  ///
  /// In en, this message translates to:
  /// **'🔥 {streak} day streak'**
  String habitStreakDays(Object streak);

  /// No description provided for @deleteHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete habit?'**
  String get deleteHabitTitle;

  /// No description provided for @deleteHabitContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{title}\" and its streak history.'**
  String deleteHabitContent(Object title);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @habitSyncError.
  ///
  /// In en, this message translates to:
  /// **'Habit sync error: {error}'**
  String habitSyncError(Object error);

  /// No description provided for @habitDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'You already have a habit named \"{title}\".'**
  String habitDuplicateTitle(Object title);

  /// No description provided for @habitUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update habit: {error}'**
  String habitUpdateFailed(Object error);

  /// No description provided for @habitDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete habit: {error}'**
  String habitDeleteFailed(Object error);

  /// No description provided for @habitSaveFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not save habit.'**
  String get habitSaveFailedGeneric;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'DeenRoutine reminder'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Time for: {title}'**
  String reminderNotificationBody(Object title);

  /// No description provided for @quizQuestionCountTitle.
  ///
  /// In en, this message translates to:
  /// **'How many questions?'**
  String get quizQuestionCountTitle;

  /// No description provided for @quizQuestionCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how many questions you\'d like to practice.'**
  String get quizQuestionCountSubtitle;

  /// No description provided for @quizAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Islamic Knowledge Quiz'**
  String get quizAppBarTitle;

  /// No description provided for @quizNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No quiz questions available yet.'**
  String get quizNoQuestions;

  /// No description provided for @quizQuestionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String quizQuestionProgress(Object current, Object total);

  /// No description provided for @quizCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get quizCorrect;

  /// No description provided for @quizCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String quizCorrectAnswer(Object answer);

  /// No description provided for @quizCheckAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check Answer'**
  String get quizCheckAnswer;

  /// No description provided for @quizNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get quizNextQuestion;

  /// No description provided for @quizSeeResults.
  ///
  /// In en, this message translates to:
  /// **'See Results'**
  String get quizSeeResults;

  /// No description provided for @quizResultsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz Results'**
  String get quizResultsAppBarTitle;

  /// No description provided for @quizOutcomeExcellentTitle.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get quizOutcomeExcellentTitle;

  /// No description provided for @quizOutcomeExcellentMessage.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah, your knowledge really shines. Keep it up!'**
  String get quizOutcomeExcellentMessage;

  /// No description provided for @quizOutcomeWellDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Well Done!'**
  String get quizOutcomeWellDoneTitle;

  /// No description provided for @quizOutcomeWellDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Good effort! A little more practice and you\'ll master it.'**
  String get quizOutcomeWellDoneMessage;

  /// No description provided for @quizOutcomeKeepLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Learning'**
  String get quizOutcomeKeepLearningTitle;

  /// No description provided for @quizOutcomeKeepLearningMessage.
  ///
  /// In en, this message translates to:
  /// **'Every attempt is a step forward. Review and try again!'**
  String get quizOutcomeKeepLearningMessage;

  /// No description provided for @quizScoreOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{score} / {total}'**
  String quizScoreOfTotal(Object score, Object total);

  /// No description provided for @quizBestScore.
  ///
  /// In en, this message translates to:
  /// **'Your best score: {score}/{total} ({pct}%)'**
  String quizBestScore(Object score, Object total, Object pct);

  /// No description provided for @quizTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get quizTryAgain;

  /// No description provided for @quizBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get quizBackToHome;

  /// No description provided for @profileAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileAppBarTitle;

  /// No description provided for @darkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeTitle;

  /// No description provided for @darkModeFollowingSystem.
  ///
  /// In en, this message translates to:
  /// **'Following system setting'**
  String get darkModeFollowingSystem;

  /// No description provided for @onLabel.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get onLabel;

  /// No description provided for @offLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offLabel;

  /// No description provided for @useSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'Use system theme'**
  String get useSystemTheme;

  /// No description provided for @prayerMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer calculation method'**
  String get prayerMethodTitle;

  /// No description provided for @prayerMethodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'MWL (default)'**
  String get prayerMethodSubtitle;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutButton;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBangla;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address looks invalid.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak — use at least 6 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
