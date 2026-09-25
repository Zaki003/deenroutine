import '../models/prayer_log.dart';

/// When one prayer can be logged, and what a log at a given instant counts
/// as: [PrayerStatus.onTime] before [onTimeEnd], [PrayerStatus.late] from
/// there until [lateEnd], [PrayerStatus.qada] after that.
class PrayerWaqtWindow {
  final DateTime start;
  final DateTime onTimeEnd;
  final DateTime lateEnd;

  const PrayerWaqtWindow({required this.start, required this.onTimeEnd, required this.lateEnd});

  bool hasStarted(DateTime at) => !at.isBefore(start);

  /// Only Asr and Isha have one - every other waqt runs right up to the
  /// point after which praying it is qada.
  bool get hasLateWindow => lateEnd.isAfter(onTimeEnd);

  /// Null before [start]: a prayer can't be logged before its time begins.
  PrayerStatus? statusAt(DateTime at) {
    if (!hasStarted(at)) return null;
    if (at.isBefore(onTimeEnd)) return PrayerStatus.onTime;
    if (at.isBefore(lateEnd)) return PrayerStatus.late;
    return PrayerStatus.qada;
  }
}

/// Asr prayed in the last stretch before Maghrib, while the sun is yellowing,
/// is disliked (makruh), so it counts as late rather than on time.
const asrMakruhBeforeMaghrib = Duration(minutes: 20);

/// Windows for all five prayers of the prayer day starting on [day]:
///
/// - Fajr: on time until sunrise; qada after (no late window).
/// - Dhuhr: on time until Asr; qada after.
/// - Asr: on time until 20 minutes before Maghrib, late for those 20
///   minutes, qada once Maghrib starts.
/// - Maghrib: on time until Isha; qada after.
/// - Isha: on time until Islamic midnight (halfway from Maghrib to the next
///   Fajr), late until the next Fajr, qada after.
///
/// [timings] are clock times ('HH:mm') for the five prayers and [sunrise]
/// the same for sunrise, as fetched for the current calendar date. When
/// [day] is yesterday (between midnight and Fajr), those same clock times
/// stand in for yesterday's - they drift by a minute or two a day, which is
/// well inside what a tap-to-log can resolve anyway. The next day's Fajr is
/// approximated the same way.
///
/// Returns null if any time is missing or unparseable.
Map<String, PrayerWaqtWindow>? prayerWindowsFor(
  DateTime day,
  Map<String, String> timings,
  String? sunrise,
) {
  final fajr = _at(day, timings['Fajr']);
  final sunriseAt = _at(day, sunrise);
  final dhuhr = _at(day, timings['Dhuhr']);
  final asr = _at(day, timings['Asr']);
  final maghrib = _at(day, timings['Maghrib']);
  final isha = _at(day, timings['Isha']);
  if (fajr == null ||
      sunriseAt == null ||
      dhuhr == null ||
      asr == null ||
      maghrib == null ||
      isha == null) {
    return null;
  }
  final nextFajr = _at(DateTime(day.year, day.month, day.day + 1), timings['Fajr'])!;
  final midnight = maghrib.add(nextFajr.difference(maghrib) ~/ 2);
  final asrOnTimeEnd = maghrib.subtract(asrMakruhBeforeMaghrib);

  return {
    'Fajr': PrayerWaqtWindow(start: fajr, onTimeEnd: sunriseAt, lateEnd: sunriseAt),
    'Dhuhr': PrayerWaqtWindow(start: dhuhr, onTimeEnd: asr, lateEnd: asr),
    'Asr': PrayerWaqtWindow(
      start: asr,
      // Guards against a pathological timetable where Asr starts less than
      // 20 minutes before Maghrib - on time still has to begin at Asr.
      onTimeEnd: asrOnTimeEnd.isAfter(asr) ? asrOnTimeEnd : asr,
      lateEnd: maghrib,
    ),
    'Maghrib': PrayerWaqtWindow(start: maghrib, onTimeEnd: isha, lateEnd: isha),
    'Isha': PrayerWaqtWindow(start: isha, onTimeEnd: midnight, lateEnd: nextFajr),
  };
}

/// The prayer day [now] belongs to: today once today's Fajr has begun,
/// otherwise yesterday (the night between midnight and Fajr still belongs
/// to yesterday's Isha). Date-only, at local midnight.
DateTime currentPrayerDay(DateTime now, String? fajrTime) {
  final today = DateTime(now.year, now.month, now.day);
  final fajr = _at(today, fajrTime);
  if (fajr != null && now.isBefore(fajr)) {
    return DateTime(now.year, now.month, now.day - 1);
  }
  return today;
}

DateTime? _at(DateTime day, String? time) {
  if (time == null) return null;
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(time);
  if (match == null) return null;
  return DateTime(day.year, day.month, day.day, int.parse(match.group(1)!), int.parse(match.group(2)!));
}
