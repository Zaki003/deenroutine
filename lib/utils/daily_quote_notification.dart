import '../l10n/app_localizations.dart';
import '../models/daily_quote.dart';

/// Title and body for a daily-quote notification. The source decides ayah vs
/// hadith: every Qur'an entry in `data/daily_quotes.json` has a source that
/// starts with "Qur'an", and every hadith with its collection's name.
({String title, String body}) dailyQuoteNotificationText(
  AppLocalizations l10n,
  DailyQuote quote, {
  required bool bangla,
}) {
  final isAyah = quote.source.startsWith("Qur'an");
  return (
    title: isAyah
        ? l10n.dailyAyahNotificationTitle
        : l10n.dailyHadithNotificationTitle,
    body: '${quote.displayText(bangla)} (${quote.source})',
  );
}
