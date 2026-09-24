import 'package:deenroutine/l10n/app_localizations.dart';
import 'package:deenroutine/models/daily_quote.dart';
import 'package:deenroutine/utils/daily_quote_notification.dart';
import 'package:deenroutine/utils/daily_quote_schedule.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The daily-quote notification has to carry the same quote the dashboard
/// shows at the moment it fires, and its schedule has to roll forward
/// correctly - both easy to get subtly wrong around UTC and month boundaries,
/// and neither observable without waiting a day on a device.
void main() {
  group('quoteDayIndex', () {
    test('starts at 0 on the epoch day and advances one per UTC day', () {
      expect(quoteDayIndex(DateTime.utc(2026, 1, 1), 120), 0);
      expect(quoteDayIndex(DateTime.utc(2026, 1, 2), 120), 1);
      expect(quoteDayIndex(DateTime.utc(2026, 1, 1, 23, 59), 120), 0);
    });

    test('wraps around the size of the bank', () {
      expect(quoteDayIndex(DateTime.utc(2026, 5, 1), 120), 0); // day 120
      expect(quoteDayIndex(DateTime.utc(2026, 5, 2), 120), 1);
    });

    test('stays in range before the epoch', () {
      expect(quoteDayIndex(DateTime.utc(2025, 12, 31), 120), 119);
    });

    test('counts the UTC day, not the local one', () {
      // 23:30 UTC on Jan 1 is already Jan 2 in Dhaka (UTC+6) - the quote must
      // still be Jan 1's, matching what the dashboard shows at that instant.
      final instant = DateTime.utc(2026, 1, 1, 23, 30);
      expect(quoteDayIndex(instant.toLocal(), 120), quoteDayIndex(instant, 120));
      expect(quoteDayIndex(instant, 120), 0);
    });
  });

  group('upcomingDailyTimes', () {
    test("starts with today when the time hasn't passed", () {
      final times = upcomingDailyTimes(DateTime(2026, 9, 25, 6, 0),
          hour: 7, minute: 30, count: 3);
      expect(times, [
        DateTime(2026, 9, 25, 7, 30),
        DateTime(2026, 9, 26, 7, 30),
        DateTime(2026, 9, 27, 7, 30),
      ]);
    });

    test('starts tomorrow once the time has passed', () {
      final times = upcomingDailyTimes(DateTime(2026, 9, 25, 8, 0),
          hour: 7, minute: 30, count: 2);
      expect(times.first, DateTime(2026, 9, 26, 7, 30));
    });

    test('starts tomorrow at the exact minute', () {
      final times = upcomingDailyTimes(DateTime(2026, 9, 25, 7, 30),
          hour: 7, minute: 30, count: 1);
      expect(times.single, DateTime(2026, 9, 26, 7, 30));
    });

    test('rolls over month ends', () {
      final times = upcomingDailyTimes(DateTime(2026, 9, 29, 8, 0),
          hour: 7, minute: 0, count: 3);
      expect(times, [
        DateTime(2026, 9, 30, 7, 0),
        DateTime(2026, 10, 1, 7, 0),
        DateTime(2026, 10, 2, 7, 0),
      ]);
    });
  });

  group('dailyQuoteNotificationText', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final bn = lookupAppLocalizations(const Locale('bn'));

    DailyQuote quote(String source, {String textBn = ''}) => DailyQuote(
          quoteId: 'q',
          text: 'Some English text.',
          source: source,
          category: 'Hope',
          textBn: textBn,
        );

    test('titles a Qur\'an source as an ayah', () {
      final text = dailyQuoteNotificationText(en, quote("Qur'an 2:286"),
          bangla: false);
      expect(text.title, "Today's ayah");
      expect(text.body, "Some English text. (Qur'an 2:286)");
    });

    test('titles anything else as a hadith', () {
      final text = dailyQuoteNotificationText(en, quote('Sahih Muslim 2699'),
          bangla: false);
      expect(text.title, "Today's hadith");
    });

    test('uses Bangla text and titles when asked, English as the fallback', () {
      final withBn = dailyQuoteNotificationText(
          bn, quote("Qur'an 2:286", textBn: 'বাংলা পাঠ'),
          bangla: true);
      expect(withBn.title, 'আজকের আয়াত');
      expect(withBn.body, "বাংলা পাঠ (Qur'an 2:286)");

      final withoutBn =
          dailyQuoteNotificationText(bn, quote("Qur'an 2:286"), bangla: true);
      expect(withoutBn.body, "Some English text. (Qur'an 2:286)");
    });
  });
}
