import 'package:deenroutine/models/prayer_log.dart';
import 'package:deenroutine/utils/prayer_check_in_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const timings = {
    'Fajr': '04:30',
    'Dhuhr': '11:50',
    'Asr': '15:15',
    'Maghrib': '17:55',
    'Isha': '19:10',
  };
  const all = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};
  DateTime at(int d, int h, int m) => DateTime(2026, 9, d, h, m);

  CheckInPlan plan(
    DateTime now, {
    int delay = 25,
    Set<String> prayers = all,
    Set<String> logged = const {},
  }) =>
      planPrayerCheckIns(
        now: now,
        timings: timings,
        sunrise: '05:45',
        delay: Duration(minutes: delay),
        prayers: prayers,
        loggedToday: logged,
        lang: 'en',
        text: (key, _) => (title: key, body: ''),
      );

  PrayerCheckIn? find(CheckInPlan p, String key, String day) {
    for (final c in p.checkIns) {
      if (c.payload.prayerKey == key && c.payload.day == day) return c;
    }
    return null;
  }

  test('asks the chosen delay into each waqt, for today and tomorrow', () {
    final p = plan(at(24, 3, 0), delay: 25);
    // 3 AM belongs to the 23rd's prayer day, so "today" is the 23rd.
    expect(find(p, 'Dhuhr', '2026-09-24')!.when, at(24, 12, 15));
    expect(find(p, 'Dhuhr', '2026-09-24')!.id, prayerCheckInIdBase + 5 + 1);
  });

  test('never later than halfway to qada, so a short waqt still gets asked', () {
    final p = plan(at(24, 6, 0), delay: 40);
    // Maghrib 17:55 to Isha 19:10 is 75 minutes; halfway is 18:32:30.
    expect(find(p, 'Maghrib', '2026-09-24')!.when, DateTime(2026, 9, 24, 18, 32, 30));
    // Dhuhr's window is long enough for the full 40 minutes.
    expect(find(p, 'Dhuhr', '2026-09-24')!.when, at(24, 12, 30));
  });

  test('skips logged, unchosen and past prayers, but keeps an open one alive', () {
    final p = plan(at(24, 13, 0), prayers: {'Dhuhr', 'Asr', 'Isha'}, logged: {'Isha'});
    expect(find(p, 'Maghrib', '2026-09-24'), isNull); // not chosen
    expect(find(p, 'Isha', '2026-09-24'), isNull); // already logged
    expect(find(p, 'Dhuhr', '2026-09-24'), isNull); // its check-in time has passed
    expect(p.keepIds, contains(prayerCheckInIdBase + 1)); // ...but Dhuhr is still open
    expect(find(p, 'Asr', '2026-09-24')!.id, prayerCheckInIdBase + 2);
    // Tomorrow's are planned whatever today's log says.
    expect(find(p, 'Isha', '2026-09-25'), isNotNull);
  });

  test('between midnight and Fajr, last night\'s Isha is still open', () {
    final p = plan(at(25, 1, 0));
    expect(p.keepIds, contains(prayerCheckInIdBase + 4));
    expect(find(p, 'Fajr', '2026-09-25')!.when, at(25, 4, 55));
  });

  test('a tap logs by the same rules as the Prayer screen', () {
    final c = find(plan(at(24, 6, 0)), 'Asr', '2026-09-24')!.payload;
    final decoded = CheckInPayload.decode(c.encode())!;
    expect(decoded.prayerKey, 'Asr');
    expect(decoded.statusAt(at(24, 17, 34)), PrayerStatus.onTime);
    expect(decoded.statusAt(at(24, 17, 40)), PrayerStatus.late);
    expect(decoded.statusAt(at(24, 18, 0)), PrayerStatus.qada);
    expect(decoded.asRepeat().isRepeat, isTrue);
  });

  test('other payloads are ignored', () {
    expect(CheckInPayload.decode(null), isNull);
    expect(CheckInPayload.decode('not json'), isNull);
    expect(CheckInPayload.decode('{"kind":"something else"}'), isNull);
  });
}
