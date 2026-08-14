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
  String get quizTabTitle => 'Quiz';

  @override
  String get quizChooseLengthLabel => 'Choose your length';

  @override
  String get quizStartButton => 'Start Quiz';

  @override
  String get quizNoAttemptsYet =>
      'Take your first quiz to set a personal best.';

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
  String get profileAppBarTitle => 'Profile';

  @override
  String get darkModeTitle => 'Dark mode';

  @override
  String get darkModeFollowingSystem => 'Following system setting';

  @override
  String get onLabel => 'On';

  @override
  String get offLabel => 'Off';

  @override
  String get useSystemTheme => 'Use system theme';

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
}
