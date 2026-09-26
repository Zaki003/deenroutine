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
  String get fullNameValidatorError => 'Enter a valid name';

  @override
  String get loginButton => 'Login';

  @override
  String get registerPromptQuestion => 'Don\'t have an account?';

  @override
  String get registerPromptAction => 'Register';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get registerButton => 'Register';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordPrompt =>
      'Enter your email and we\'ll send a link to reset your password.';

  @override
  String get sendResetLinkButton => 'Send reset link';

  @override
  String get resetLinkSentTitle => 'Check your email';

  @override
  String resetLinkSentMessage(Object email) {
    return 'If an account exists for $email, we\'ve sent a link to reset the password.';
  }

  @override
  String get onboardingTagline => 'Make deen your routine.';

  @override
  String get onboardingWelcomeSubtitle =>
      '3 quick steps to set up your prayer times and habit reminders.';

  @override
  String get onboardingGetStartedButton => 'Get started';

  @override
  String get onboardingLocationHeadline => 'Find your prayer times';

  @override
  String get onboardingLocationBody =>
      'DeenRoutine uses your location only to show accurate prayer times for your area. Your coordinates are rounded to about 1km and never sold or shared.';

  @override
  String get onboardingAllowLocationButton => 'Allow location';

  @override
  String get onboardingEnterCityManually => 'Enter a city manually instead';

  @override
  String get onboardingNotificationHeadline => 'Stay on track';

  @override
  String get onboardingNotificationBody =>
      'Get gentle habit reminders, a daily ayah or hadith, and a weekly summary. You can turn any of them off under Settings → Notifications.';

  @override
  String get onboardingAllowNotificationsButton => 'Allow notifications';

  @override
  String get onboardingSkipNotificationsButton => 'Skip for now';

  @override
  String get onboardingExactAlarmHeadline =>
      'One more step for reminders to actually ring';

  @override
  String get onboardingExactAlarmBody =>
      'Android needs \"Alarms & reminders\" turned on for DeenRoutine, or your habit reminders will silently never fire.';

  @override
  String get onboardingOpenSettingsButton => 'Open settings';

  @override
  String get onboardingExactAlarmLaterButton => 'I\'ll do this later';

  @override
  String get onboardingHabitPickerHeadline => 'Add your first habits';

  @override
  String get onboardingHabitPickerSubtitle =>
      'Pick a few to get started — you can add more anytime.';

  @override
  String onboardingAddHabitsButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count habits and finish',
      one: 'Add 1 habit and finish',
    );
    return '$_temp0';
  }

  @override
  String get onboardingSkipHabitsButton => 'Skip — I\'ll add my own';

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
  String get retryButton => 'Retry';

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String get prayerUnavailableTitle => 'Prayer times unavailable';

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
  String get navLearn => 'Learn';

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
  String barakahSummaryRemainingNoPrayer(
      Object done, Object total, Object remaining) {
    return '$done of $total habits complete today — $remaining to go.';
  }

  @override
  String barakahSummaryComplete(Object total) {
    return 'All $total habits complete today. Well done!';
  }

  @override
  String get prayerScreenTitle => 'Prayer Times';

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
  String get prayerNotifyOnTooltip => 'Turn off adhan notification';

  @override
  String get prayerNotifyOffTooltip => 'Turn on adhan notification';

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
  String get learnTabTitle => 'Learn';

  @override
  String get learnTopicLocked =>
      'Finish the topics before this one to unlock it.';

  @override
  String learnLessonsProgress(Object done, Object total) {
    return '$done/$total lessons';
  }

  @override
  String get learnLessonFinishButton => 'Finish';

  @override
  String learnPathCompleteTitle(Object topic) {
    return '$topic complete!';
  }

  @override
  String learnPathCompleteMessage(Object count) {
    return 'All $count lessons done';
  }

  @override
  String get learnTakeAssessmentButton => 'Take the assessment';

  @override
  String get learnSkipForNowButton => 'Skip for now';

  @override
  String learnNextTopicUnlockedMessage(Object topic) {
    return '$topic is now unlocked';
  }

  @override
  String get learnAllTopicsCompleteMessage => 'You\'ve completed every topic!';

  @override
  String get learnSyncError =>
      'Couldn\'t sync your Learn progress. Retrying...';

  @override
  String get learnSaveFailed => 'Couldn\'t save your progress. Try again.';

  @override
  String learnPathProgress(Object done, Object total) {
    return '$done/$total topics';
  }

  @override
  String get learnMilestoneLabel => 'Milestone';

  @override
  String get learnTopicBelief => 'Aqeedah';

  @override
  String get learnTopicPillars => 'Arkan';

  @override
  String get learnTopicSalah => 'Salah';

  @override
  String get learnTopicQuran => 'Quran';

  @override
  String get learnTopicSeerah => 'Seerah';

  @override
  String get learnTopicProphets => 'Anbiya';

  @override
  String get learnTopicHistory => 'Tarikh';

  @override
  String get learnTopicRamadan => 'Ramadan';

  @override
  String get learnTopicHajj => 'Hajj';

  @override
  String get learnTopicManners => 'Adab';

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
  String get newTodoTitle => 'New To-do';

  @override
  String get editHabitTitle => 'Edit Habit';

  @override
  String get editTodoTitle => 'Edit To-do';

  @override
  String get habitTitleLabel => 'Habit title';

  @override
  String get habitTitleValidatorError => 'Please enter a habit title';

  @override
  String get habitTitleTooLongError => 'Keep the title under 60 characters';

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
  String get onceDueDateLabel => 'Due date';

  @override
  String get onceTodayOption => 'Today';

  @override
  String get oncePickDateOption => 'Pick a date';

  @override
  String get onceReminderTitle => 'Reminder';

  @override
  String onceReminderAtDateTime(Object date, Object time) {
    return '$date, $time';
  }

  @override
  String get saveHabitButton => 'Save Habit';

  @override
  String get saveOneTimeTaskButton => 'Save One-Time Task';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesContent =>
      'You have unsaved changes. If you leave now, they\'ll be lost.';

  @override
  String get discardButton => 'Discard';

  @override
  String get keepEditingButton => 'Keep Editing';

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
  String get frequencyOnce => 'Once';

  @override
  String get onceSectionTitle => 'To-dos';

  @override
  String get onceDueTodayTag => 'Today';

  @override
  String get onceOverdueTag => 'Overdue';

  @override
  String onceDueOnTag(Object date) {
    return 'Due $date';
  }

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
  String get templateReadQuran => 'Read Qur\'an';

  @override
  String get templateDhikrAfterPrayer => 'Dhikr after prayer';

  @override
  String get templateMorningEveningAdhkar => 'Morning & evening adhkar';

  @override
  String get templateAdhkarMorning => 'Morning';

  @override
  String get templateAdhkarEvening => 'Evening';

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
  String get milestoneTitle3 => 'Alhamdulillah!';

  @override
  String milestoneSubtitle3(Object days, Object habitTitle) {
    return '$days-day streak — $habitTitle';
  }

  @override
  String get milestoneTitle7 => 'Alhamdulillah!';

  @override
  String milestoneSubtitle7(Object days, Object habitTitle) {
    return 'A full week — $habitTitle, $days days strong';
  }

  @override
  String get milestoneTitle30 => 'Alhamdulillah! 🌙';

  @override
  String milestoneSubtitle30(Object days, Object habitTitle) {
    return 'A full month of $habitTitle — $days days';
  }

  @override
  String get milestoneTitle100 => 'MashaAllah!';

  @override
  String milestoneSubtitle100(Object days, Object habitTitle) {
    return '$days days of $habitTitle — incredible consistency!';
  }

  @override
  String get milestoneTitle365 => 'الحمد لله';

  @override
  String milestoneSubtitle365(Object days, Object habitTitle) {
    return 'A full year of $habitTitle — $days days. Truly remarkable!';
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
  String get timerBypassTitle => 'Mark as done?';

  @override
  String timerBypassContent(Object title) {
    return 'This skips today\'s timer for \"$title\" and marks it complete anyway.';
  }

  @override
  String get markAsDoneButton => 'Mark as done';

  @override
  String get deleteButton => 'Delete';

  @override
  String get deleteAccountButton => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountWarning =>
      'This permanently deletes your habits, streaks, prayer log, quiz results, Learn progress, and profile. This can\'t be undone.';

  @override
  String get deleteAccountPasswordPrompt => 'Enter your password to confirm.';

  @override
  String get deleteAccountWrongPassword =>
      'That password doesn\'t match your account.';

  @override
  String get deleteAccountResetSent =>
      'Password reset email sent — check your inbox.';

  @override
  String get editButton => 'Edit';

  @override
  String get habitSyncError => 'Couldn\'t sync your habits. Retrying...';

  @override
  String habitDuplicateTitle(Object title) {
    return 'You already have a habit named \"$title\".';
  }

  @override
  String get habitUpdateFailed => 'Couldn\'t update that habit. Try again.';

  @override
  String get habitDeleteFailed => 'Couldn\'t delete that habit. Try again.';

  @override
  String get habitSaveFailedGeneric => 'Could not save habit.';

  @override
  String get reminderNotificationTitle => 'DeenRoutine reminder';

  @override
  String reminderNotificationBody(Object title) {
    return 'Time for: $title';
  }

  @override
  String prayerNotificationBody(Object prayer) {
    return 'It\'s time for $prayer.';
  }

  @override
  String get alarmStopButton => 'Stop';

  @override
  String learnAssessmentAppBarTitle(Object topic) {
    return '$topic Assessment';
  }

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
  String get quizTryAgain => 'Try Again';

  @override
  String get quizBackToHome => 'Back to Home';

  @override
  String get profilePreferencesLabel => 'PREFERENCES';

  @override
  String get profileAccountLabel => 'ACCOUNT';

  @override
  String get profileAboutLabel => 'ABOUT';

  @override
  String get settingsTitle => 'Settings';

  @override
  String habitsCompletedOnDay(int count) {
    return '$count completed';
  }

  @override
  String get noHabitsCompletedOnDay => 'No habits completed';

  @override
  String get noAdsTitle => 'No ads, ever';

  @override
  String get noAdsBody =>
      'DeenRoutine has no ad network and never sells or shares your data. Usage analytics are optional — off unless you turn them on in Preferences.';

  @override
  String get shareInviteTitle => 'Share DeenRoutine';

  @override
  String get shareInviteBody =>
      'Know someone who\'d like this too? A quick share goes a long way.';

  @override
  String get shareInviteButton => 'Share';

  @override
  String get notNowButton => 'Not now';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get usageAnalyticsTitle => 'Usage Analytics';

  @override
  String get usageAnalyticsBody =>
      'Help improve DeenRoutine by sharing anonymous usage data — which features get used, never your habit titles or content. Off by default.';

  @override
  String get linkOpenFailed => 'Couldn\'t open that link.';

  @override
  String get editNameTitle => 'Edit name';

  @override
  String get chooseAvatarTitle => 'Choose an avatar';

  @override
  String get avatarMaleLabel => 'Male';

  @override
  String get avatarFemaleLabel => 'Female';

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
  String get notificationsDailyQuoteLabel => 'DAILY AYAH & HADITH';

  @override
  String get dailyQuoteNotifyTitle => 'Send a daily ayah or hadith';

  @override
  String get dailyQuoteNotifySubtitle =>
      'One short reminder a day — the same one shown on your home screen.';

  @override
  String get dailyQuoteNotifyTimeLabel => 'Time';

  @override
  String get dailyQuoteNotifyFootnote =>
      'It can arrive a few minutes late, depending on your phone\'s battery settings.';

  @override
  String get notificationsStatusLabel => 'STATUS';

  @override
  String get alarmsAndRemindersLabel => 'Alarms & reminders';

  @override
  String get permissionAllowed => 'Allowed';

  @override
  String get permissionNotAllowed => 'Not allowed';

  @override
  String get notificationsProblemNote =>
      'Reminders may not reach you until this is allowed. Tap the row to change it in your phone\'s settings.';

  @override
  String get dailyAyahNotificationTitle => 'Today\'s ayah';

  @override
  String get dailyHadithNotificationTitle => 'Today\'s hadith';

  @override
  String get notificationsRemindersLabel => 'HABIT REMINDERS';

  @override
  String get encouragingRemindersTitle => 'Encouraging reminder wording';

  @override
  String get encouragingRemindersSubtitle =>
      'Short Islamic messages on your habit reminders, instead of the same line every day.';

  @override
  String get remindersSkipDoneNote =>
      'A reminder is skipped for any habit you\'ve already finished that day.';

  @override
  String get notificationsNudgesLabel => 'MOTIVATION';

  @override
  String get streakNudgeSettingTitle => 'Streak reminder';

  @override
  String get streakNudgeSettingSubtitle =>
      'One evening nudge when a streak of 3+ days is at risk, only if you haven\'t done it yet.';

  @override
  String get weeklySummarySettingTitle => 'Friday summary';

  @override
  String get weeklySummarySettingSubtitle =>
      'Jumu\'ah Mubarak, with a look back at your week.';

  @override
  String get comebackSettingTitle => 'Come-back message';

  @override
  String get comebackSettingSubtitle =>
      'A gentle message if you\'ve been away for a few days: at most twice, then silence.';

  @override
  String get reminderMsgDo1 =>
      'Bismillah — a small step now beats a big plan later.';

  @override
  String get reminderMsgDo2 =>
      'The deeds most beloved to Allah are those done consistently, even if they are few. (Sahih al-Bukhari 6464; Sahih Muslim 783)';

  @override
  String get reminderMsgDo3 =>
      'Make it easy on yourself — even a few minutes counts, in shaa Allah.';

  @override
  String get reminderMsgDo4 =>
      'Take a moment for it. Barakah grows in steady routines.';

  @override
  String get reminderMsgDo5 =>
      'Keep going — steady effort adds up, in shaa Allah.';

  @override
  String get reminderMsgDo6 =>
      'A calm moment for this, then on with your day. You can do it, in shaa Allah.';

  @override
  String get reminderMsgAvoid1 =>
      'A steady day is built one choice at a time. Stay on course, in shaa Allah.';

  @override
  String get reminderMsgAvoid2 =>
      'Be patient today. Indeed, Allah is with the patient. (Qur\'an 2:153)';

  @override
  String get reminderMsgAvoid3 =>
      'You\'re doing well. Another day of staying on course, in shaa Allah.';

  @override
  String streakNudgeNotificationTitle(int count) {
    return 'Keep your $count-day streak alive';
  }

  @override
  String streakNudgeNotificationBody(Object habit) {
    return '$habit — a few hours left today. Even a small effort keeps it going, in shaa Allah.';
  }

  @override
  String get weeklySummaryNotificationTitle => 'Jumu\'ah Mubarak';

  @override
  String weeklySummaryNotificationBodyStats(int done, Object habit) {
    return 'You checked off $done habits this week. Best habit: $habit.';
  }

  @override
  String get weeklySummaryNotificationBodyGeneric =>
      'Take a moment to look back on your week, then begin the next one with bismillah.';

  @override
  String get comebackNotificationTitle => 'Your habits are still here';

  @override
  String get comebackNotificationBody =>
      'Every day is a fresh start. Begin small today, bismillah.';

  @override
  String get comebackSecondNotificationTitle => 'Take it gently';

  @override
  String get comebackSecondNotificationBody =>
      'Allah does not burden a soul with more than it can bear. (Qur\'an 2:286)';

  @override
  String get prayerMethodTitle => 'Prayer calculation method';

  @override
  String get prayerMethodKarachi => 'Karachi';

  @override
  String get prayerMethodIsna => 'ISNA';

  @override
  String get prayerMethodMwl => 'MWL';

  @override
  String get prayerMethodUmmAlQura => 'Umm al-Qura';

  @override
  String get asrMethodTitle => 'Asr calculation';

  @override
  String get asrMethodStandard => 'Standard';

  @override
  String get asrMethodHanafi => 'Hanafi';

  @override
  String get profileLocationLabel => 'Location';

  @override
  String get logoutButton => 'Log out';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get favoritesTitle => 'Favourite Ayats & Hadiths';

  @override
  String favoritesCountLabel(int count, int max) {
    return '$count/$max saved';
  }

  @override
  String get favoritesEmptyBody =>
      'Tap the heart on a daily quote to save it here.';

  @override
  String favoritesLimitReachedMessage(int max) {
    return 'You\'ve saved the maximum of $max for now. Remove one to add another.';
  }

  @override
  String get favoriteAddTooltip => 'Save to favourites';

  @override
  String get favoriteRemoveTooltip => 'Remove from favourites';

  @override
  String get authErrorWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorInvalidCredential =>
      'Incorrect email or password. New here? Sign up below.';

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

  @override
  String get authErrorDeviceLimit =>
      'Maximum of 3 accounts on this device. Log in instead.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please wait and try again.';

  @override
  String get prayerStatusOnTime => 'Prayed on time';

  @override
  String get prayerStatusLate => 'Prayed late';

  @override
  String get prayerStatusQada => 'Made up (qada)';

  @override
  String get prayerStatusMissed => 'Not prayed';

  @override
  String get prayerNotStartedYet => 'Not started yet';

  @override
  String get prayerOptionOnTime => 'On time';

  @override
  String get prayerOptionLate => 'Late';

  @override
  String get prayerOptionQada => 'Made up later (qada)';

  @override
  String get prayerOptionMissed => 'Not prayed';

  @override
  String get prayerOptionClear => 'Clear';

  @override
  String prayerLogSheetTitle(String prayer) {
    return 'Mark $prayer as';
  }

  @override
  String prayerDayTodayProgress(int count, int total) {
    return 'TODAY · $count OF $total PRAYED';
  }

  @override
  String prayerDayYesterdayProgress(int count, int total) {
    return 'YESTERDAY · $count OF $total PRAYED';
  }

  @override
  String get prayerMarkHint => 'mark as prayed';

  @override
  String get prayerUndoHint => 'undo';

  @override
  String get prayerMoreOptionsHint => 'more options';

  @override
  String get prayerLogSaveFailed => 'Couldn\'t save that prayer. Try again.';

  @override
  String get prayerLogSyncFailed => 'Couldn\'t load your prayers. Retrying...';

  @override
  String get prayerStatusExcused => 'Excused';

  @override
  String get prayerOptionExcused => 'Excused all day';

  @override
  String get prayerExcusedSubtitle => 'Pauses your streak without breaking it';

  @override
  String get prayerStreakLabel => 'Days, all 5 prayed';

  @override
  String get prayerPrayedLabel => 'Prayed';

  @override
  String prayerWeakestInsight(String prayer) {
    return '$prayer is your hardest. An alarm could help.';
  }

  @override
  String prayerWeakestInsightPlain(String prayer) {
    return '$prayer is your hardest right now.';
  }

  @override
  String get prayerTurnOnAlarm => 'Turn on';

  @override
  String get prayerLegendQada => 'Qada';

  @override
  String get prayerLegendNotLogged => 'Not logged';

  @override
  String get prayerLogHistoryFailed => 'Couldn\'t load your prayer history.';

  @override
  String get prayerDayToday => 'TODAY';

  @override
  String get prayerDayYesterday => 'YESTERDAY';

  @override
  String get prayerInsightsTitle => 'Prayer insights';

  @override
  String get prayerInsightsSubtitle => 'Last 30 days';

  @override
  String get prayerInsightsEmpty =>
      'Tick off your prayers on the Prayer tab and your insights will show up here.';

  @override
  String get notificationsPrayerCheckInsLabel => 'PRAYER CHECK-INS';

  @override
  String get prayerCheckInSettingTitle => 'Ask if I\'ve prayed';

  @override
  String get prayerCheckInSettingSubtitle =>
      'A quiet reminder partway through each waqt, with a button to log the prayer';

  @override
  String get prayerCheckInPrayersLabel => 'For these prayers';

  @override
  String get prayerCheckInDelayLabel => 'Ask after';

  @override
  String get prayerCheckInDelaySubtitle => 'From the start of the waqt';

  @override
  String prayerCheckInDelayMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get prayerCheckInFootnote =>
      'Later asks once more, 30 minutes on. You won\'t be asked about a prayer that\'s already logged.';

  @override
  String prayerCheckInTitle(String prayer) {
    return 'Have you prayed $prayer?';
  }

  @override
  String prayerCheckInBody(String prayer, String time) {
    return 'Tap Prayed to log it. $prayer lasts until $time.';
  }

  @override
  String get prayerCheckInPrayed => 'Prayed';

  @override
  String get prayerCheckInLater => 'Later';

  @override
  String prayerCheckInLogged(String prayer, String status) {
    return '$prayer logged · $status';
  }

  @override
  String get prayerCheckInLoggedBody =>
      'You can change it anytime on the Prayer tab.';

  @override
  String get habitInsightsTitle => 'Habit insights';

  @override
  String get habitInsightsSubtitle => 'Last 4 weeks';

  @override
  String get habitBestStreakLabel => 'Best streak';

  @override
  String get habitRateLabel => '4-week rate';

  @override
  String get habitCheckInsLabel => 'Check-ins';

  @override
  String habitWeekProgress(int done, int total) {
    return 'This week · $done of $total';
  }

  @override
  String get habitGridLess => 'Less';

  @override
  String get habitGridMore => 'More';

  @override
  String get habitMilestonesLabel => 'Milestones';

  @override
  String habitMilestoneDays(int days) {
    return '$days days';
  }

  @override
  String habitMilestoneReached(int days) {
    return '$days-day streak reached';
  }

  @override
  String habitMilestoneNotReached(int days) {
    return '$days-day streak not reached yet';
  }

  @override
  String get habitInsightsLoadFailed => 'Couldn\'t load your habit history.';

  @override
  String get habitPerfectDayLegend => 'Every habit done';

  @override
  String habitPerfectDays(int count) {
    return '$count days with every habit done';
  }
}
