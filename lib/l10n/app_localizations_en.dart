// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DeenRoutine';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailValidatorError => 'Enter a valid email';

  @override
  String get passwordValidatorError => 'Min 6 characters';

  @override
  String get requiredValidatorError => 'Required';

  @override
  String get loginButton => 'Login';

  @override
  String get registerPrompt => 'Don\'t have an account? Register';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get registerButton => 'Register';

  @override
  String get barakahCircleTitle => 'Barakah Circle';

  @override
  String habitsDoneToday(Object done, Object total) {
    return '$done of $total habits done today';
  }

  @override
  String get todaysHabitsTitle => 'Today\'s Habits';

  @override
  String get noHabitsYet => 'No habits yet. Tap + to add your first one.';

  @override
  String get noHabitsToday =>
      'Nothing scheduled for today. Tap + to add a habit.';

  @override
  String seeAllHabits(Object count) {
    return 'See all $count habits';
  }

  @override
  String prayerTimesUnavailable(Object error) {
    return 'Prayer times unavailable: $error';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navHabits => 'Habits';

  @override
  String get navPrayer => 'Prayer';

  @override
  String get navQuiz => 'Quiz';

  @override
  String get navProfile => 'Profile';

  @override
  String get assalamuAlaikumGreeting => 'ASSALAMU ALAIKUM';

  @override
  String get todayLabel => 'TODAY';

  @override
  String get nextPrayerLabel => 'NEXT PRAYER';

  @override
  String barakahSummaryRemaining(
      Object done, Object total, Object remaining, Object prayer) {
    return '$done of $total habits complete today — $remaining to go before $prayer.';
  }

  @override
  String barakahSummaryComplete(Object total) {
    return 'All $total habits complete today. Well done!';
  }

  @override
  String get prayerScreenTitle => 'Prayer Times';

  @override
  String get prayerMethodFullName => 'Muslim World League';

  @override
  String prayerRemainingLong(Object time) {
    return '$time remaining';
  }

  @override
  String prayerRemainingShort(Object time) {
    return 'in $time';
  }

  @override
  String get updateLocationTooltip => 'Update location';

  @override
  String get updateLocationTitle => 'Update location';

  @override
  String get updateLocationConfirm => 'Use current location';

  @override
  String get updateLocationSuccess => 'Location updated';

  @override
  String get currentLocationGps => 'Currently using GPS';

  @override
  String currentLocationCity(Object city) {
    return 'Currently: $city';
  }

  @override
  String get useCurrentLocationSubtitle => 'Uses your device\'s GPS';

  @override
  String get enterCityTitle => 'Enter a city';

  @override
  String get enterCitySubtitle => 'No location permission needed';

  @override
  String get chooseCityTitle => 'Choose your city';

  @override
  String get searchCityHint => 'Search for a city';

  @override
  String get citySearchPrivacyNote =>
      'Searching happens on your device — nothing is sent until you pick a city.';

  @override
  String get citySearchEmptyHint => 'Start typing to search for a city';

  @override
  String get citySearchNoResults => 'No matching cities found';

  @override
  String get quizTabTitle => 'Quiz';

  @override
  String get quizChooseLengthLabel => 'Choose your length';

  @override
  String get quizStartButton => 'Start Quiz';

  @override
  String quizNoAttemptsYet(Object count) {
    return 'Take your first $count-question quiz to set a personal best.';
  }

  @override
  String quizMinutesEstimate(Object minutes) {
    return '~$minutes min';
  }

  @override
  String get prayerErrorLocationDisabled => 'Location services are disabled.';

  @override
  String get prayerErrorPermissionDenied => 'Location permission denied.';

  @override
  String get prayerErrorPermissionDeniedForever =>
      'Location permission permanently denied.';

  @override
  String prayerErrorFetchFailed(Object statusCode) {
    return 'Failed to fetch prayer times ($statusCode)';
  }

  @override
  String get prayerErrorUnknown =>
      'Something went wrong while loading prayer times.';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get newHabitTitle => 'New Habit';

  @override
  String get editHabitTitle => 'Edit Habit';

  @override
  String get habitTitleLabel => 'Habit title';

  @override
  String get habitTitleValidatorError => 'Please enter a habit title';

  @override
  String get categoryLabel => 'Category';

  @override
  String get frequencyLabel => 'Frequency';

  @override
  String get repeatOnLabel => 'Repeat on';

  @override
  String get selectAtLeastOneDay => 'Select at least one day';

  @override
  String get dailyReminderTitle => 'Daily reminder';

  @override
  String get reminderOffSubtitle => 'Off — tap to set a time';

  @override
  String reminderAtTime(Object time) {
    return 'At $time';
  }

  @override
  String get saveHabitButton => 'Save Habit';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get categoryIslam => 'Islam';

  @override
  String get categoryLifestyle => 'Lifestyle';

  @override
  String get categoryLearn => 'Learn';

  @override
  String get categoryWork => 'Work';

  @override
  String get frequencyDaily => 'Daily';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get frequencySpecificDays => 'Specific days';

  @override
  String get trackingTypeSectionLabel => 'Tracking type';

  @override
  String get trackingTypeYesNoLabel => 'Yes / No';

  @override
  String get trackingTypeYesNoBlurb => 'One tap to mark done';

  @override
  String get trackingTypeNumericLabel => 'Numeric';

  @override
  String get trackingTypeNumericBlurb => 'Log a count vs. a target';

  @override
  String get trackingTypeTimerLabel => 'Timer';

  @override
  String get trackingTypeTimerBlurb => 'Track minutes spent';

  @override
  String get trackingTypeChecklistLabel => 'Checklist';

  @override
  String get trackingTypeChecklistBlurb => 'Multiple steps, one habit';

  @override
  String get trackingTypeRatingLabel => 'Rating';

  @override
  String get trackingTypeRatingBlurb => 'Rate how it went';

  @override
  String get trackingTypeAvoidanceLabel => 'Avoidance';

  @override
  String get trackingTypeAvoidanceBlurb => 'Success is staying at zero';

  @override
  String get yesNoInfoNote =>
      'Marked complete with a single tap on the habit card — no extra input needed.';

  @override
  String get avoidanceInfoNote =>
      'Check in once a day to confirm you stayed clear of it. The streak only breaks on a day you log a slip.';

  @override
  String get avoidanceLogSlipLink => 'Log a slip';

  @override
  String get avoidanceSlipLoggedToday => 'Slip logged today';

  @override
  String get avoidanceConfirmTitle => 'Log a slip for today?';

  @override
  String get avoidanceConfirmButton => 'Log it';

  @override
  String get numericTargetLabel => 'Daily target';

  @override
  String get numericUnitLabel => 'Unit';

  @override
  String get numericUnitPagesChip => 'pages';

  @override
  String get numericUnitGlassesChip => 'glasses';

  @override
  String get numericUnitRakahsChip => 'rakahs';

  @override
  String get numericUnitKmChip => 'km';

  @override
  String get numericUnitCustomHint => 'Custom unit';

  @override
  String get numericUnitDefault => 'times';

  @override
  String numericProgressSubtitle(Object current, Object target, Object unit) {
    return '$current/$target $unit';
  }

  @override
  String get timerTargetLabel => 'Target duration';

  @override
  String timerMinutesChip(Object minutes) {
    return '$minutes min';
  }

  @override
  String get timerCustomMinutesLabel => 'Custom (minutes)';

  @override
  String timerProgressSubtitle(Object remaining) {
    return '$remaining left';
  }

  @override
  String get checklistItemsLabel => 'Checklist items';

  @override
  String get checklistItemInputHint => 'e.g. Istighfar 100x';

  @override
  String get checklistEmptyError => 'Add at least one item';

  @override
  String checklistProgressSubtitle(Object done, Object total) {
    return '$done/$total items';
  }

  @override
  String get ratingScaleLabel => 'Scale';

  @override
  String ratingOutOfOption(Object n) {
    return 'out of $n';
  }

  @override
  String ratingProgressSubtitle(Object value, Object scale) {
    return '$value/$scale tonight';
  }

  @override
  String get createYourOwnHabit => 'Create your own habit';

  @override
  String get templatePrayFiveTimes => 'Pray 5 times daily';

  @override
  String get templateReadQuran => 'Read Qur\'an';

  @override
  String get templateDhikrAfterPrayer => 'Dhikr after prayer';

  @override
  String get templateDrinkWater => 'Drink water';

  @override
  String get templateSleepEarly => 'Sleep by 11pm';

  @override
  String get templateShortWalk => '10-minute walk';

  @override
  String get templateReadPages => 'Read 20 pages';

  @override
  String get templateLearnNewWord => 'Learn a new word';

  @override
  String get templateWatchEducationalVideo => 'Watch an educational video';

  @override
  String get templateDeepWorkBlock => 'Deep work block';

  @override
  String get templateInboxZero => 'Inbox zero';

  @override
  String get templatePlanTomorrow => 'Plan tomorrow';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String habitStreakDays(Object streak) {
    return '🔥 $streak day streak';
  }

  @override
  String get deleteHabitTitle => 'Delete habit?';

  @override
  String deleteHabitContent(Object title) {
    return 'This will permanently delete \"$title\" and its streak history.';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get deleteAccountButton => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountWarning =>
      'This permanently deletes your habits, streaks, quiz results, and profile. This can\'t be undone.';

  @override
  String get deleteAccountPasswordPrompt => 'Enter your password to confirm.';

  @override
  String get editButton => 'Edit';

  @override
  String habitSyncError(Object error) {
    return 'Habit sync error: $error';
  }

  @override
  String habitDuplicateTitle(Object title) {
    return 'You already have a habit named \"$title\".';
  }

  @override
  String habitUpdateFailed(Object error) {
    return 'Could not update habit: $error';
  }

  @override
  String habitDeleteFailed(Object error) {
    return 'Could not delete habit: $error';
  }

  @override
  String get habitSaveFailedGeneric => 'Could not save habit.';

  @override
  String get reminderNotificationTitle => 'DeenRoutine reminder';

  @override
  String reminderNotificationBody(Object title) {
    return 'Time for: $title';
  }

  @override
  String get quizQuestionCountTitle => 'How many questions?';

  @override
  String get quizQuestionCountSubtitle =>
      'Choose how many questions you\'d like to practice.';

  @override
  String get quizAppBarTitle => 'Islamic Knowledge Quiz';

  @override
  String get quizNoQuestions => 'No quiz questions available yet.';

  @override
  String quizQuestionProgress(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String get quizCorrect => 'Correct!';

  @override
  String quizCorrectAnswer(Object answer) {
    return 'Correct answer: $answer';
  }

  @override
  String get quizCheckAnswer => 'Check Answer';

  @override
  String get quizNextQuestion => 'Next Question';

  @override
  String get quizSeeResults => 'See Results';

  @override
  String get quizResultsAppBarTitle => 'Quiz Results';

  @override
  String quizResultQuestionLabel(Object number) {
    return 'Question $number';
  }

  @override
  String get quizOutcomeExcellentTitle => 'Excellent!';

  @override
  String get quizOutcomeExcellentMessage =>
      'MashaAllah, your knowledge really shines. Keep it up!';

  @override
  String get quizOutcomeWellDoneTitle => 'Well Done!';

  @override
  String get quizOutcomeWellDoneMessage =>
      'Good effort! A little more practice and you\'ll master it.';

  @override
  String get quizOutcomeKeepLearningTitle => 'Keep Learning';

  @override
  String get quizOutcomeKeepLearningMessage =>
      'Every attempt is a step forward. Review and try again!';

  @override
  String quizScoreOfTotal(Object score, Object total) {
    return '$score / $total';
  }

  @override
  String quizBestScore(Object score, Object total, Object pct) {
    return 'Your best score: $score/$total ($pct%)';
  }

  @override
  String get quizTryAgain => 'Try Again';

  @override
  String get quizBackToHome => 'Back to Home';

  @override
  String get profilePreferencesLabel => 'PREFERENCES';

  @override
  String get profileAccountLabel => 'ACCOUNT';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceSystem => 'System';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get prayerMethodTitle => 'Prayer calculation method';

  @override
  String get prayerMethodSubtitle => 'MWL (default)';

  @override
  String get logoutButton => 'Log out';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get authErrorWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorInvalidEmail => 'That email address looks invalid.';

  @override
  String get authErrorEmailInUse =>
      'An account already exists with this email.';

  @override
  String get authErrorWeakPassword =>
      'Password is too weak — use at least 6 characters.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authErrorRequiresRecentLogin =>
      'For your security, please log out and back in, then try again.';
}
