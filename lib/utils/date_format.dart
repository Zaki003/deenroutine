import 'package:intl/intl.dart';

/// Short "Fri, Sep 20" style date in the app's current locale — used
/// wherever a [HabitFrequency.once] habit's due date is shown (the add-form
/// date picker, its reminder subtitle, and the Habits tab's due-state tag).
String formatShortDate(String localeName, DateTime date) =>
    DateFormat.MMMEd(localeName).format(date);
