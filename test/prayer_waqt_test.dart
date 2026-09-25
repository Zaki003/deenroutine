import 'package:deenroutine/models/prayer_log.dart';
import 'package:deenroutine/utils/prayer_waqt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Roughly Dhaka in late September, Hanafi Asr.
  const timings = {
    'Fajr': '04:30',
    'Dhuhr': '11:50',
    'Asr': '15:15',
    'Maghrib': '17:55',
    'Isha': '19:10',
  };
  const sunrise = '05:45';
  final day = DateTime(2026, 9, 24);
  final w = prayerWindowsFor(day, timings, sunrise)!;
  DateTime at(int d, int h, int m) => DateTime(2026, 9, d, h, m);

  test('Fajr is on time until sunrise, then qada', () {
    expect(w['Fajr']!.statusAt(at(24, 4, 29)), isNull);
    expect(w['Fajr']!.statusAt(at(24, 5, 44)), PrayerStatus.onTime);
    expect(w['Fajr']!.statusAt(at(24, 5, 45)), PrayerStatus.qada);
    expect(w['Fajr']!.hasLateWindow, isFalse);
  });

  test('Dhuhr and Maghrib go straight from on time to qada', () {
    expect(w['Dhuhr']!.statusAt(at(24, 15, 14)), PrayerStatus.onTime);
    expect(w['Dhuhr']!.statusAt(at(24, 15, 15)), PrayerStatus.qada);
    expect(w['Maghrib']!.statusAt(at(24, 19, 9)), PrayerStatus.onTime);
    expect(w['Maghrib']!.statusAt(at(24, 19, 10)), PrayerStatus.qada);
  });

  test('Asr is late for the 20 minutes before Maghrib', () {
    expect(w['Asr']!.statusAt(at(24, 17, 34)), PrayerStatus.onTime);
    expect(w['Asr']!.statusAt(at(24, 17, 35)), PrayerStatus.late);
    expect(w['Asr']!.statusAt(at(24, 17, 55)), PrayerStatus.qada);
  });

  test('Isha is on time until Islamic midnight, late until Fajr', () {
    // Halfway from 17:55 to the next day's 04:30 is 23:12:30.
    expect(w['Isha']!.statusAt(at(24, 23, 12)), PrayerStatus.onTime);
    expect(w['Isha']!.statusAt(at(24, 23, 13)), PrayerStatus.late);
    expect(w['Isha']!.statusAt(at(25, 4, 29)), PrayerStatus.late);
    expect(w['Isha']!.statusAt(at(25, 4, 30)), PrayerStatus.qada);
  });

  test('the prayer day rolls over at Fajr, not midnight', () {
    expect(currentPrayerDay(at(25, 0, 30), '04:30'), DateTime(2026, 9, 24));
    expect(currentPrayerDay(at(25, 4, 30), '04:30'), DateTime(2026, 9, 25));
    expect(currentPrayerDay(DateTime(2026, 10, 1, 1), '04:30'), DateTime(2026, 9, 30));
  });

  test('missing sunrise disables tracking rather than guessing', () {
    expect(prayerWindowsFor(day, timings, null), isNull);
  });
}
