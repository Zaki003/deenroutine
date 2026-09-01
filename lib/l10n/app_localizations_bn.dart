// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'DeenRoutine';

  @override
  String get emailLabel => 'ইমেইল';

  @override
  String get passwordLabel => 'পাসওয়ার্ড';

  @override
  String get emailValidatorError => 'সঠিক ইমেইল ঠিকানা দিন';

  @override
  String get passwordValidatorError => 'কমপক্ষে ৬ অক্ষর';

  @override
  String get requiredValidatorError => 'আবশ্যক';

  @override
  String get loginButton => 'লগইন';

  @override
  String get registerPrompt => 'অ্যাকাউন্ট নেই? নিবন্ধন করুন';

  @override
  String get createAccountTitle => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get fullNameLabel => 'পূর্ণ নাম';

  @override
  String get registerButton => 'নিবন্ধন করুন';

  @override
  String get onboardingTagline => 'দ্বীনকে করুন আপনার রুটিন।';

  @override
  String get onboardingWelcomeSubtitle =>
      'নামাজের সময় ও অভ্যাসের অনুস্মারক চালু করতে মাত্র ৩টি ধাপ।';

  @override
  String get onboardingGetStartedButton => 'শুরু করুন';

  @override
  String get onboardingLocationHeadline => 'আপনার নামাজের সময় খুঁজে বের করুন';

  @override
  String get onboardingLocationBody =>
      'আপনার এলাকার সঠিক নামাজের সময় দেখাতে DeenRoutine শুধু আপনার অবস্থান ব্যবহার করে। আপনার স্থানাঙ্ক প্রায় ১ কিমি পর্যন্ত গোলাকার করা হয় এবং কখনো বিক্রি বা শেয়ার করা হয় না।';

  @override
  String get onboardingAllowLocationButton => 'অবস্থানের অনুমতি দিন';

  @override
  String get onboardingEnterCityManually => 'পরিবর্তে শহরের নাম লিখুন';

  @override
  String get onboardingNotificationHeadline => 'নিয়মিত থাকুন';

  @override
  String get onboardingNotificationBody =>
      'শুধু আপনি বেছে নেওয়া অভ্যাসের জন্যই একটি হালকা অনুস্মারক পাবেন — আর কিছু নয়।';

  @override
  String get onboardingAllowNotificationsButton => 'নোটিফিকেশনের অনুমতি দিন';

  @override
  String get onboardingSkipNotificationsButton => 'আপাতত বাদ দিন';

  @override
  String get onboardingExactAlarmHeadline =>
      'অনুস্মারক সত্যিই বাজতে আরেকটি ধাপ বাকি';

  @override
  String get onboardingExactAlarmBody =>
      'অনুস্মারক কাজ করার জন্য অ্যান্ড্রয়েডে DeenRoutine-এর \"অ্যালার্ম ও অনুস্মারক\" চালু করা দরকার, নয়তো আপনার অভ্যাসের অনুস্মারক নীরবেই বাজবে না।';

  @override
  String get onboardingOpenSettingsButton => 'সেটিংস খুলুন';

  @override
  String get onboardingExactAlarmLaterButton => 'পরে করব';

  @override
  String get onboardingHabitPickerHeadline => 'আপনার প্রথম অভ্যাসগুলো যোগ করুন';

  @override
  String get onboardingHabitPickerSubtitle =>
      'শুরু করতে কয়েকটি বেছে নিন — পরেও যোগ করতে পারবেন।';

  @override
  String onboardingAddHabitsButton(Object count) {
    return '$count টি অভ্যাস যোগ করে শেষ করুন';
  }

  @override
  String get onboardingSkipHabitsButton => 'বাদ দিন — নিজের মতো যোগ করব';

  @override
  String get barakahCircleTitle => 'বারাকাহ বৃত্ত';

  @override
  String habitsDoneToday(Object done, Object total) {
    return '$total টির মধ্যে $done টি অভ্যাস আজ সম্পন্ন হয়েছে';
  }

  @override
  String get todaysHabitsTitle => 'আজকের অভ্যাস';

  @override
  String get noHabitsYet => 'এখনো কোনো অভ্যাস নেই। প্রথমটি যোগ করতে + চাপুন।';

  @override
  String get noHabitsToday =>
      'আজকের জন্য কোনো অভ্যাস নির্ধারিত নেই। একটি যোগ করতে + চাপুন।';

  @override
  String seeAllHabits(Object count) {
    return 'সব $count টি অভ্যাস দেখুন';
  }

  @override
  String get retryButton => 'আবার চেষ্টা করুন';

  @override
  String get prayerUnavailableTitle => 'নামাজের সময় পাওয়া যায়নি';

  @override
  String prayerTimesUnavailable(Object error) {
    return 'নামাজের সময় পাওয়া যায়নি: $error';
  }

  @override
  String get navHome => 'হোম';

  @override
  String get navHabits => 'অভ্যাস';

  @override
  String get navPrayer => 'নামাজ';

  @override
  String get navQuiz => 'কুইজ';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String get assalamuAlaikumGreeting => 'আসসালামু আলাইকুম';

  @override
  String get todayLabel => 'আজ';

  @override
  String get nextPrayerLabel => 'পরবর্তী নামাজ';

  @override
  String barakahSummaryRemaining(
      Object done, Object total, Object remaining, Object prayer) {
    return '$total টির মধ্যে $done টি অভ্যাস আজ সম্পন্ন — $prayer-এর আগে আরও $remaining টি বাকি।';
  }

  @override
  String barakahSummaryComplete(Object total) {
    return 'আজকের সব $total টি অভ্যাস সম্পন্ন হয়েছে। চমৎকার!';
  }

  @override
  String get prayerScreenTitle => 'নামাজের সময়';

  @override
  String get prayerMethodFullName => 'মুসলিম ওয়ার্ল্ড লীগ';

  @override
  String prayerRemainingLong(Object time) {
    return '$time বাকি';
  }

  @override
  String prayerRemainingShort(Object time) {
    return '$time পরে';
  }

  @override
  String get updateLocationTooltip => 'অবস্থান আপডেট করুন';

  @override
  String get updateLocationTitle => 'অবস্থান আপডেট করুন';

  @override
  String get updateLocationConfirm => 'বর্তমান অবস্থান ব্যবহার করুন';

  @override
  String get updateLocationSuccess => 'অবস্থান আপডেট হয়েছে';

  @override
  String get currentLocationGps =>
      'বর্তমানে ডিভাইসের অবস্থান ব্যবহার করা হচ্ছে';

  @override
  String currentLocationCity(Object city) {
    return 'বর্তমান অবস্থান: $city';
  }

  @override
  String get useCurrentLocationSubtitle => 'আপনার ডিভাইসের অবস্থান ব্যবহার করে';

  @override
  String get enterCityTitle => 'শহরের নাম লিখুন';

  @override
  String get enterCitySubtitle => 'অবস্থানের অনুমতির প্রয়োজন নেই';

  @override
  String get chooseCityTitle => 'আপনার শহর বেছে নিন';

  @override
  String get searchCityHint => 'শহর খুঁজুন';

  @override
  String get citySearchPrivacyNote =>
      'খোঁজা আপনার ডিভাইসেই হয় — শহর বেছে নেওয়ার আগে কিছুই পাঠানো হয় না।';

  @override
  String get citySearchEmptyHint => 'শহর খুঁজতে টাইপ করা শুরু করুন';

  @override
  String get citySearchNoResults => 'কোনো মিলযুক্ত শহর পাওয়া যায়নি';

  @override
  String get quizTabTitle => 'কুইজ';

  @override
  String get quizChooseLengthLabel => 'দৈর্ঘ্য বেছে নিন';

  @override
  String get quizStartButton => 'কুইজ শুরু করুন';

  @override
  String quizNoAttemptsYet(Object count) {
    return 'ব্যক্তিগত সেরা রেকর্ড করতে $count টি প্রশ্নের প্রথম কুইজ দিন।';
  }

  @override
  String quizMinutesEstimate(Object minutes) {
    return '~$minutes মিনিট';
  }

  @override
  String get prayerErrorLocationDisabled => 'লোকেশন সার্ভিস বন্ধ আছে।';

  @override
  String get prayerErrorPermissionDenied =>
      'লোকেশনের অনুমতি প্রত্যাখ্যান করা হয়েছে।';

  @override
  String get prayerErrorPermissionDeniedForever =>
      'লোকেশনের অনুমতি স্থায়ীভাবে প্রত্যাখ্যান করা হয়েছে।';

  @override
  String prayerErrorFetchFailed(Object statusCode) {
    return 'নামাজের সময় আনতে ব্যর্থ ($statusCode)';
  }

  @override
  String get prayerErrorUnknown => 'নামাজের সময় লোড করতে সমস্যা হয়েছে।';

  @override
  String get prayerFajr => 'ফজর';

  @override
  String get prayerDhuhr => 'যোহর';

  @override
  String get prayerAsr => 'আসর';

  @override
  String get prayerMaghrib => 'মাগরিব';

  @override
  String get prayerIsha => 'এশা';

  @override
  String get newHabitTitle => 'নতুন অভ্যাস';

  @override
  String get editHabitTitle => 'অভ্যাস সম্পাদনা করুন';

  @override
  String get habitTitleLabel => 'অভ্যাসের নাম';

  @override
  String get habitTitleValidatorError => 'অভ্যাসের নাম লিখুন';

  @override
  String get categoryLabel => 'বিভাগ';

  @override
  String get frequencyLabel => 'পুনরাবৃত্তি';

  @override
  String get repeatOnLabel => 'যেসব দিনে হবে';

  @override
  String get selectAtLeastOneDay => 'কমপক্ষে একটি দিন নির্বাচন করুন';

  @override
  String get dailyReminderTitle => 'দৈনিক অনুস্মারক';

  @override
  String get reminderOffSubtitle => 'বন্ধ — সময় নির্ধারণ করতে চাপুন';

  @override
  String reminderAtTime(Object time) {
    return '$time টায়';
  }

  @override
  String get saveHabitButton => 'অভ্যাস সংরক্ষণ করুন';

  @override
  String get saveChangesButton => 'পরিবর্তন সংরক্ষণ করুন';

  @override
  String get categoryIslam => 'ইসলাম';

  @override
  String get categoryLifestyle => 'জীবনযাপন';

  @override
  String get categoryLearn => 'শেখা';

  @override
  String get categoryWork => 'কাজ';

  @override
  String get frequencyDaily => 'প্রতিদিন';

  @override
  String get frequencyWeekly => 'সাপ্তাহিক';

  @override
  String get frequencySpecificDays => 'নির্দিষ্ট দিন';

  @override
  String get trackingTypeSectionLabel => 'ট্র্যাকিং ধরন';

  @override
  String get trackingTypeYesNoLabel => 'হ্যাঁ / না';

  @override
  String get trackingTypeYesNoBlurb => 'একবার চাপলেই সম্পন্ন';

  @override
  String get trackingTypeNumericLabel => 'সংখ্যা';

  @override
  String get trackingTypeNumericBlurb => 'লক্ষ্যের বিপরীতে গণনা লগ করুন';

  @override
  String get trackingTypeTimerLabel => 'টাইমার';

  @override
  String get trackingTypeTimerBlurb => 'কত মিনিট ব্যয় হলো তা ট্র্যাক করুন';

  @override
  String get trackingTypeChecklistLabel => 'চেকলিস্ট';

  @override
  String get trackingTypeChecklistBlurb => 'একই অভ্যাসে একাধিক ধাপ';

  @override
  String get trackingTypeRatingLabel => 'রেটিং';

  @override
  String get trackingTypeRatingBlurb => 'কেমন হলো তার রেটিং দিন';

  @override
  String get trackingTypeAvoidanceLabel => 'পরিহার';

  @override
  String get trackingTypeAvoidanceBlurb => 'শূন্যে থাকাই সাফল্য';

  @override
  String get yesNoInfoNote =>
      'হ্যাবিট কার্ডে একবার চাপলেই সম্পন্ন হিসেবে চিহ্নিত হবে — অতিরিক্ত কিছু লেখার দরকার নেই।';

  @override
  String get avoidanceInfoNote =>
      'প্রতিদিন একবার নিশ্চিত করুন যে আপনি এটি থেকে বিরত ছিলেন। যেদিন আপনার ভুল হয়ে যাবে, শুধু সেদিনই ধারাবাহিকতা ভাঙবে।';

  @override
  String get avoidanceLogSlipLink => 'আজ ভুল হয়েছে?';

  @override
  String get avoidanceSlipLoggedToday => 'আজ ভুল হয়ে গেছে';

  @override
  String get avoidanceConfirmTitle => 'আজ সত্যিই ভুল হয়ে গেছে?';

  @override
  String get avoidanceConfirmButton => 'হ্যাঁ, হয়েছে';

  @override
  String get numericTargetLabel => 'দৈনিক লক্ষ্য';

  @override
  String get numericUnitLabel => 'একক';

  @override
  String get numericUnitPagesChip => 'পৃষ্ঠা';

  @override
  String get numericUnitGlassesChip => 'গ্লাস';

  @override
  String get numericUnitRakahsChip => 'রাকাত';

  @override
  String get numericUnitKmChip => 'কিমি';

  @override
  String get numericUnitCustomHint => 'নিজস্ব একক';

  @override
  String get numericUnitDefault => 'বার';

  @override
  String numericProgressSubtitle(Object current, Object target, Object unit) {
    return '$target এর মধ্যে $current $unit';
  }

  @override
  String get timerTargetLabel => 'লক্ষ্য সময়কাল';

  @override
  String timerMinutesChip(Object minutes) {
    return '$minutes মিনিট';
  }

  @override
  String get timerCustomMinutesLabel => 'নিজস্ব (মিনিট)';

  @override
  String timerProgressSubtitle(Object remaining) {
    return '$remaining বাকি';
  }

  @override
  String get checklistItemsLabel => 'চেকলিস্ট আইটেম';

  @override
  String get checklistItemInputHint => 'যেমন: ইস্তিগফার ১০০ বার';

  @override
  String get checklistEmptyError => 'কমপক্ষে একটি আইটেম যোগ করুন';

  @override
  String checklistProgressSubtitle(Object done, Object total) {
    return '$total টির মধ্যে $done টি';
  }

  @override
  String get ratingScaleLabel => 'স্কেল';

  @override
  String ratingOutOfOption(Object n) {
    return '$n এর মধ্যে';
  }

  @override
  String ratingProgressSubtitle(Object value, Object scale) {
    return 'আজ রাতে $scale এর মধ্যে $value';
  }

  @override
  String get createYourOwnHabit => 'নিজের অভ্যাস তৈরি করুন';

  @override
  String get templatePrayFiveTimes => 'প্রতিদিন ৫ ওয়াক্ত নামাজ পড়ুন';

  @override
  String get templateReadQuran => 'কুরআন তিলাওয়াত করুন';

  @override
  String get templateDhikrAfterPrayer => 'নামাজের পর জিকির করুন';

  @override
  String get templateDrinkWater => 'পানি পান করুন';

  @override
  String get templateSleepEarly => 'রাত ১১টার মধ্যে ঘুমান';

  @override
  String get templateShortWalk => '১০ মিনিট হাঁটুন';

  @override
  String get templateReadPages => '২০ পৃষ্ঠা পড়ুন';

  @override
  String get templateLearnNewWord => 'একটি নতুন শব্দ শিখুন';

  @override
  String get templateWatchEducationalVideo => 'একটি শিক্ষামূলক ভিডিও দেখুন';

  @override
  String get templateDeepWorkBlock => 'গভীর মনোযোগে কাজ করুন';

  @override
  String get templateInboxZero => 'ইনবক্স খালি করুন';

  @override
  String get templatePlanTomorrow => 'আগামীকালের পরিকল্পনা করুন';

  @override
  String get weekdaySun => 'রবি';

  @override
  String get weekdayMon => 'সোম';

  @override
  String get weekdayTue => 'মঙ্গল';

  @override
  String get weekdayWed => 'বুধ';

  @override
  String get weekdayThu => 'বৃহ';

  @override
  String get weekdayFri => 'শুক্র';

  @override
  String get weekdaySat => 'শনি';

  @override
  String habitStreakDays(Object streak) {
    return '🔥 $streak দিনের ধারাবাহিকতা';
  }

  @override
  String get milestoneTitle3 => 'আলহামদুলিল্লাহ!';

  @override
  String milestoneSubtitle3(Object days, Object habitTitle) {
    return '$days দিনের ধারাবাহিকতা — $habitTitle';
  }

  @override
  String get milestoneTitle7 => 'আলহামদুলিল্লাহ!';

  @override
  String milestoneSubtitle7(Object days, Object habitTitle) {
    return 'পুরো এক সপ্তাহ — $habitTitle, $days দিন ধরে অবিচল';
  }

  @override
  String get milestoneTitle30 => 'আলহামদুলিল্লাহ! 🌙';

  @override
  String milestoneSubtitle30(Object days, Object habitTitle) {
    return '$habitTitle-এর পুরো এক মাস — $days দিন';
  }

  @override
  String get milestoneTitle100 => 'মাশাআল্লাহ!';

  @override
  String milestoneSubtitle100(Object days, Object habitTitle) {
    return '$habitTitle-এর $days দিন — অসাধারণ ধারাবাহিকতা!';
  }

  @override
  String get milestoneTitle365 => 'الحمد لله';

  @override
  String milestoneSubtitle365(Object days, Object habitTitle) {
    return '$habitTitle-এর পুরো এক বছর — $days দিন। সত্যিই অসাধারণ!';
  }

  @override
  String get deleteHabitTitle => 'অভ্যাস মুছবেন?';

  @override
  String deleteHabitContent(Object title) {
    return 'এটি \"$title\" এবং এর ধারাবাহিকতার ইতিহাস স্থায়ীভাবে মুছে ফেলবে।';
  }

  @override
  String get cancelButton => 'বাতিল';

  @override
  String get deleteButton => 'মুছুন';

  @override
  String get deleteAccountButton => 'অ্যাকাউন্ট মুছুন';

  @override
  String get deleteAccountTitle => 'আপনার অ্যাকাউন্ট মুছে ফেলবেন?';

  @override
  String get deleteAccountWarning =>
      'এটি আপনার অভ্যাস, ধারাবাহিকতা, কুইজ ফলাফল এবং প্রোফাইল স্থায়ীভাবে মুছে ফেলবে। এটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get deleteAccountPasswordPrompt =>
      'নিশ্চিত করতে আপনার পাসওয়ার্ড লিখুন।';

  @override
  String get editButton => 'সম্পাদনা';

  @override
  String get habitSyncError =>
      'অভ্যাস সিঙ্ক করা যায়নি। আবার চেষ্টা করা হচ্ছে...';

  @override
  String habitDuplicateTitle(Object title) {
    return '\"$title\" নামে আপনার আগে থেকেই একটি অভ্যাস আছে।';
  }

  @override
  String get habitUpdateFailed => 'অভ্যাস আপডেট করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get habitDeleteFailed => 'অভ্যাস মুছে ফেলা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get habitSaveFailedGeneric => 'অভ্যাস সংরক্ষণ করা যায়নি।';

  @override
  String get reminderNotificationTitle => 'DeenRoutine অনুস্মারক';

  @override
  String reminderNotificationBody(Object title) {
    return 'এখন সময়: $title';
  }

  @override
  String get quizQuestionCountTitle => 'কতগুলো প্রশ্ন?';

  @override
  String get quizQuestionCountSubtitle =>
      'আপনি কতগুলো প্রশ্ন অনুশীলন করতে চান তা নির্বাচন করুন।';

  @override
  String get quizAppBarTitle => 'ইসলামিক জ্ঞান কুইজ';

  @override
  String get quizNoQuestions => 'এখনো কোনো কুইজ প্রশ্ন নেই।';

  @override
  String quizQuestionProgress(Object current, Object total) {
    return 'প্রশ্ন $total টির মধ্যে $current';
  }

  @override
  String get quizCorrect => 'সঠিক!';

  @override
  String quizCorrectAnswer(Object answer) {
    return 'সঠিক উত্তর: $answer';
  }

  @override
  String get quizCheckAnswer => 'উত্তর যাচাই করুন';

  @override
  String get quizNextQuestion => 'পরবর্তী প্রশ্ন';

  @override
  String get quizSeeResults => 'ফলাফল দেখুন';

  @override
  String get quizResultsAppBarTitle => 'কুইজের ফলাফল';

  @override
  String quizResultQuestionLabel(Object number) {
    return 'প্রশ্ন $number';
  }

  @override
  String get quizOutcomeExcellentTitle => 'চমৎকার!';

  @override
  String get quizOutcomeExcellentMessage =>
      'মাশাআল্লাহ, আপনার জ্ঞান সত্যিই উজ্জ্বল। এভাবেই চালিয়ে যান!';

  @override
  String get quizOutcomeWellDoneTitle => 'সুন্দর হয়েছে!';

  @override
  String get quizOutcomeWellDoneMessage =>
      'চেষ্টা ভালো হয়েছে! আরেকটু অনুশীলন করলেই দক্ষ হয়ে যাবেন।';

  @override
  String get quizOutcomeKeepLearningTitle => 'শেখা চালিয়ে যান';

  @override
  String get quizOutcomeKeepLearningMessage =>
      'প্রতিটি চেষ্টাই একধাপ এগিয়ে যাওয়া। পুনরায় দেখুন এবং আবার চেষ্টা করুন!';

  @override
  String quizScoreOfTotal(Object score, Object total) {
    return '$score / $total';
  }

  @override
  String quizBestScore(Object score, Object total, Object pct) {
    return 'আপনার সেরা স্কোর: $score/$total ($pct%)';
  }

  @override
  String get quizTryAgain => 'আবার চেষ্টা করুন';

  @override
  String get quizBackToHome => 'হোমে ফিরে যান';

  @override
  String get profilePreferencesLabel => 'পছন্দসমূহ';

  @override
  String get profileAccountLabel => 'অ্যাকাউন্ট';

  @override
  String get profileAboutLabel => 'সম্পর্কে';

  @override
  String get noAdsTitle => 'কোনো বিজ্ঞাপন নেই, কখনোই না';

  @override
  String get noAdsBody =>
      'DeenRoutine-এর কোনো বিজ্ঞাপন নেটওয়ার্ক নেই এবং আমরা কখনো আপনার তথ্য বিক্রি বা শেয়ার করি না। ব্যবহার বিশ্লেষণ ঐচ্ছিক — আপনি প্রেফারেন্সে চালু না করা পর্যন্ত বন্ধ থাকে।';

  @override
  String get privacyPolicyLabel => 'গোপনীয়তা নীতি';

  @override
  String get usageAnalyticsTitle => 'ব্যবহার বিশ্লেষণ';

  @override
  String get usageAnalyticsBody =>
      'DeenRoutine উন্নত করতে বেনামী ব্যবহারের তথ্য শেয়ার করে সাহায্য করুন — কোন ফিচার ব্যবহৃত হচ্ছে তা, কখনো আপনার অভ্যাসের শিরোনাম বা বিষয়বস্তু নয়। ডিফল্টভাবে বন্ধ থাকে।';

  @override
  String get linkOpenFailed => 'লিঙ্কটি খোলা যায়নি।';

  @override
  String get appearanceTitle => 'থিম';

  @override
  String get appearanceLight => 'লাইট';

  @override
  String get appearanceDark => 'ডার্ক';

  @override
  String get appearanceSystem => 'সিস্টেম';

  @override
  String get notificationsTitle => 'নোটিফিকেশন';

  @override
  String get prayerMethodTitle => 'নামাজের সময় গণনার পদ্ধতি';

  @override
  String get prayerMethodSubtitle => 'MWL (ডিফল্ট)';

  @override
  String get logoutButton => 'লগ আউট';

  @override
  String get languageTitle => 'ভাষা';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get authErrorWrongPassword => 'ভুল পাসওয়ার্ড। আবার চেষ্টা করুন।';

  @override
  String get authErrorUserNotFound =>
      'এই ইমেইল দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি।';

  @override
  String get authErrorInvalidEmail => 'ইমেইল ঠিকানাটি সঠিক মনে হচ্ছে না।';

  @override
  String get authErrorEmailInUse =>
      'এই ইমেইল দিয়ে ইতিমধ্যে একটি অ্যাকাউন্ট আছে।';

  @override
  String get authErrorWeakPassword =>
      'পাসওয়ার্ড খুবই দুর্বল — কমপক্ষে ৬ অক্ষর ব্যবহার করুন।';

  @override
  String get authErrorGeneric => 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get authErrorRequiresRecentLogin =>
      'নিরাপত্তার জন্য, লগ আউট করে আবার লগইন করুন এবং আবার চেষ্টা করুন।';
}
