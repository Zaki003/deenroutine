import 'dart:convert';

import '../models/prayer_log.dart';
import 'prayer_waqt.dart';

/// Prayer check-ins: an opt-in, Android-only "Have you prayed Dhuhr?"
/// notification partway through each waqt, with a Prayed action that logs the
/// prayer without opening the app. The planning here is pure so it can be
/// tested; [PrayerCheckInScheduler] turns a plan into notifications, and
/// `prayerCheckInActionHandler` handles the buttons.

/// IDs 2_000_000_200..209 (see the band table in notification_plan.dart):
/// slots 0-4 are the current prayer day's five prayers, 5-9 the next day's.
const int prayerCheckInIdBase = 2000000200;
const int prayerCheckInSlots = 10;

/// The "ask after" choices offered in settings, in minutes from the start of
/// the waqt, and the default.
const List<int> checkInDelayChoices = [15, 25, 40];
const int defaultCheckInDelayMinutes = 25;

/// How long "Later" waits before asking again. It asks again only once.
const Duration checkInLaterDelay = Duration(minutes: 30);

const String checkInPrayedActionId = 'prayer_checkin_prayed';
const String checkInLaterActionId = 'prayer_checkin_later';

/// One planned check-in.
class PrayerCheckIn {
  final int id;
  final DateTime when;
  final CheckInPayload payload;

  const PrayerCheckIn({required this.id, required this.when, required this.payload});
}

/// Everything the notification's buttons need, carried in the notification
/// itself: the action handler runs in a background isolate with nothing
/// loaded, so it shouldn't have to fetch prayer times or settings to work out
/// what a tap means.
class CheckInPayload {
  final String prayerKey;

  /// [PrayerLog.dayKey] of the prayer day the check-in is for.
  final String day;

  /// When a tap stops counting as on time, and then as late - the same
  /// boundaries [PrayerWaqtWindow] uses in the app.
  final DateTime onTimeEnd;
  final DateTime lateEnd;

  /// 'en' or 'bn', for the confirmation text.
  final String lang;
  final String title;
  final String body;

  /// Set on the one repeat "Later" schedules, which offers no second Later.
  final bool isRepeat;

  const CheckInPayload({
    required this.prayerKey,
    required this.day,
    required this.onTimeEnd,
    required this.lateEnd,
    required this.lang,
    required this.title,
    required this.body,
    this.isRepeat = false,
  });

  /// What a tap at [at] logs - the same rule as a tap on the Prayer screen.
  PrayerStatus statusAt(DateTime at) {
    if (at.isBefore(onTimeEnd)) return PrayerStatus.onTime;
    if (at.isBefore(lateEnd)) return PrayerStatus.late;
    return PrayerStatus.qada;
  }

  CheckInPayload asRepeat() => CheckInPayload(
        prayerKey: prayerKey,
        day: day,
        onTimeEnd: onTimeEnd,
        lateEnd: lateEnd,
        lang: lang,
        title: title,
        body: body,
        isRepeat: true,
      );

  String encode() => jsonEncode({
        'kind': 'prayerCheckIn',
        'k': prayerKey,
        'd': day,
        'o': onTimeEnd.millisecondsSinceEpoch,
        'l': lateEnd.millisecondsSinceEpoch,
        'lang': lang,
        't': title,
        'b': body,
        'r': isRepeat,
      });

  /// Null for anything that isn't a check-in payload.
  static CheckInPayload? decode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map || m['kind'] != 'prayerCheckIn') return null;
      return CheckInPayload(
        prayerKey: m['k'] as String,
        day: m['d'] as String,
        onTimeEnd: DateTime.fromMillisecondsSinceEpoch(m['o'] as int),
        lateEnd: DateTime.fromMillisecondsSinceEpoch(m['l'] as int),
        lang: m['lang'] as String,
        title: m['t'] as String,
        body: m['b'] as String,
        isRepeat: m['r'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The result of planning: what to schedule, and which pending IDs to leave
/// alone even though nothing new is scheduled for them.
class CheckInPlan {
  final List<PrayerCheckIn> checkIns;

  /// Prayers whose check-in time has passed but that are still open and
  /// unlogged - a pending "Later" repeat for one of these must survive the
  /// sweep that cancels everything else in the band.
  final Set<int> keepIds;

  const CheckInPlan(this.checkIns, this.keepIds);

  Set<int> get wantedIds => {for (final c in checkIns) c.id, ...keepIds};
}

/// Check-ins for the current prayer day and the next, for [prayers] only,
/// [delay] after each waqt begins - but never later than halfway through the
/// time before the prayer turns qada, so a short waqt (Maghrib, or Fajr before
/// sunrise) still gets asked while there's time. Prayers already logged on
/// the current prayer day ([loggedToday], any status) are skipped, as are
/// times already past.
///
/// The next day's windows reuse today's clock times, like the rest of prayer
/// tracking - scheduling it at all means someone who doesn't open the app for
/// a day still gets asked. [text] builds each notification's title and body.
CheckInPlan planPrayerCheckIns({
  required DateTime now,
  required Map<String, String> timings,
  required String? sunrise,
  required Duration delay,
  required Set<String> prayers,
  required Set<String> loggedToday,
  required String lang,
  required ({String title, String body}) Function(String prayerKey, DateTime lateEnd) text,
}) {
  final checkIns = <PrayerCheckIn>[];
  final keep = <int>{};
  final today = currentPrayerDay(now, timings['Fajr']);
  for (var offset = 0; offset < 2; offset++) {
    final day = DateTime(today.year, today.month, today.day + offset);
    final windows = prayerWindowsFor(day, timings, sunrise);
    if (windows == null) continue;
    for (var i = 0; i < PrayerLog.prayerKeys.length; i++) {
      final key = PrayerLog.prayerKeys[i];
      if (!prayers.contains(key)) continue;
      if (offset == 0 && loggedToday.contains(key)) continue;
      final w = windows[key]!;
      final id = prayerCheckInIdBase + offset * PrayerLog.prayerKeys.length + i;
      final halfway = w.start.add(w.lateEnd.difference(w.start) ~/ 2);
      final asked = w.start.add(delay);
      final when = asked.isBefore(halfway) ? asked : halfway;
      if (!when.isAfter(now)) {
        if (now.isBefore(w.lateEnd)) keep.add(id);
        continue;
      }
      final t = text(key, w.lateEnd);
      checkIns.add(PrayerCheckIn(
        id: id,
        when: when,
        payload: CheckInPayload(
          prayerKey: key,
          day: PrayerLog.dayKey(day),
          onTimeEnd: w.onTimeEnd,
          lateEnd: w.lateEnd,
          lang: lang,
          title: t.title,
          body: t.body,
        ),
      ));
    }
  }
  return CheckInPlan(checkIns, keep);
}
