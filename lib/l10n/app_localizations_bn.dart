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
  String seeAllHabits(Object count) {
    return 'সব $count টি অভ্যাস দেখুন';
  }

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
  String get quizTabTitle => 'কুইজ';

  @override
  String get quizChooseLengthLabel => 'দৈর্ঘ্য বেছে নিন';

  @override
  String get quizStartButton => 'কুইজ শুরু করুন';

  @override
  String get quizNoAttemptsYet => 'ব্যক্তিগত সেরা রেকর্ড করতে প্রথম কুইজ দিন।';

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
  String get editButton => 'সম্পাদনা';

  @override
  String habitSyncError(Object error) {
    return 'অভ্যাস সিঙ্ক করতে সমস্যা: $error';
  }

  @override
  String habitDuplicateTitle(Object title) {
    return '\"$title\" নামে আপনার আগে থেকেই একটি অভ্যাস আছে।';
  }

  @override
  String habitUpdateFailed(Object error) {
    return 'অভ্যাস আপডেট করা যায়নি: $error';
  }

  @override
  String habitDeleteFailed(Object error) {
    return 'অভ্যাস মুছে ফেলা যায়নি: $error';
  }

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
  String get profileAppBarTitle => 'প্রোফাইল';

  @override
  String get darkModeTitle => 'ডার্ক মোড';

  @override
  String get darkModeFollowingSystem => 'সিস্টেম সেটিং অনুসরণ করছে';

  @override
  String get onLabel => 'চালু';

  @override
  String get offLabel => 'বন্ধ';

  @override
  String get useSystemTheme => 'সিস্টেম থিম ব্যবহার করুন';

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
}
