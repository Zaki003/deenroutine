import 'package:intl/intl.dart';

/// intl's bundled CLDR data doesn't keep every Bangla month's যুক্তবর্ণ
/// (conjunct) whole when abbreviating - e.g. সেপ্টেম্বর shortens to সেপ,
/// severing the প্ট cluster instead of completing or stopping before it.
/// This app keeps its own short forms instead, indexed by DateTime.month-1;
/// English is unaffected and still comes from intl below.
const _bnShortMonths = [
  'জানু', 'ফেব্রু', 'মার্চ', 'এপ্রি', 'মে', 'জুন',
  'জুল', 'আগস্ট', 'সেপ্ট', 'অক্টো', 'নভে', 'ডিসে',
];

/// Short "Fri, Sep 20" style date in the app's current locale — used
/// wherever a [HabitFrequency.once] habit's due date is shown (the add-form
/// date picker, its reminder subtitle, and the Habits tab's due-state tag).
String formatShortDate(String localeName, DateTime date) {
  if (localeName == 'bn') {
    final weekday = DateFormat.E('bn').format(date);
    final day = DateFormat.d('bn').format(date);
    return '$weekday $day ${_bnShortMonths[date.month - 1]}';
  }
  return DateFormat.MMMEd(localeName).format(date);
}
