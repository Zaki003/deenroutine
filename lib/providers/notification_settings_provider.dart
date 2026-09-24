import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/daily_quote_notification.dart';
import '../utils/daily_quote_schedule.dart';

/// The user's choices for the daily ayah/hadith notification - off by default
/// (onboarding promises reminders "only for the habits you choose"), persisted
/// on the device like [ThemeProvider]'s choice - plus the rolling schedule
/// that delivers it.
///
/// The notification is a window of the next [NotificationService.quoteNotificationSlots]
/// days, each carrying that day's real quote, and it only runs out if the app
/// goes unopened for that long: [refreshSchedule] tops it up on every launch and
/// resume.
class NotificationSettingsProvider extends ChangeNotifier {
  static const _enabledKey = 'daily_quote_notify_enabled';
  static const _hourKey = 'daily_quote_notify_hour';
  static const _minuteKey = 'daily_quote_notify_minute';
  static const _defaultHour = 7;
  static const _refreshEvery = Duration(hours: 6);

  final NotificationService _notifications = NotificationService();
  final FirestoreService _firestore = FirestoreService();

  bool _loaded = false;
  bool _quoteEnabled = false;
  int _quoteHour = _defaultHour;
  int _quoteMinute = 0;
  bool _bangla = false;

  late final Future<void> _loading;

  // Bumped by anything that supersedes an in-flight schedule run (a newer
  // run, a cancel), so the older one stops before sending another schedule
  // call rather than resurrecting notifications the user just turned off.
  int _generation = 0;
  String? _lastScheduledKey;
  DateTime? _lastScheduledAt;

  bool get loaded => _loaded;
  bool get quoteEnabled => _quoteEnabled;
  int get quoteHour => _quoteHour;
  int get quoteMinute => _quoteMinute;

  NotificationSettingsProvider() {
    _loading = _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _quoteEnabled = prefs.getBool(_enabledKey) ?? false;
    _quoteHour = prefs.getInt(_hourKey) ?? _defaultHour;
    _quoteMinute = prefs.getInt(_minuteKey) ?? 0;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setQuoteEnabled(bool enabled) async {
    await _loading;
    _quoteEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled) {
      // Asked in context, at the moment the user opts in, rather than at
      // launch - a no-op when already granted (or below Android 13).
      await _notifications.requestPermission();
      await refreshSchedule(force: true);
    } else {
      await cancelScheduled();
    }
  }

  Future<void> setQuoteTime(int hour, int minute) async {
    await _loading;
    _quoteHour = hour;
    _quoteMinute = minute;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
    if (_quoteEnabled) await refreshSchedule(force: true);
  }

  /// Fed from [LocaleProvider] (see app.dart) so the scheduled text follows a
  /// language switch instead of staying in the old language for up to a week.
  /// Runs during a build, so it must not notify listeners synchronously -
  /// [refreshSchedule] only does that after its first await.
  void onLocaleChanged(bool bangla) {
    if (_bangla == bangla) return;
    _bangla = bangla;
    if (_quoteEnabled) refreshSchedule();
  }

  /// Rebuilds the rolling window of scheduled quotes. Skipped when nothing
  /// changed and it was done recently, so calling it on every app resume
  /// stays cheap.
  Future<void> refreshSchedule({bool force = false}) async {
    await _loading;
    if (!_quoteEnabled) return;

    final key = '$_quoteHour:$_quoteMinute:$_bangla';
    final last = _lastScheduledAt;
    if (!force &&
        key == _lastScheduledKey &&
        last != null &&
        DateTime.now().difference(last) < _refreshEvery) {
      return;
    }

    final generation = ++_generation;
    try {
      final times = upcomingDailyTimes(
        DateTime.now(),
        hour: _quoteHour,
        minute: _quoteMinute,
        count: NotificationService.quoteNotificationSlots,
      );
      final quotes = await _firestore.getDailyQuotesFor(times);
      if (generation != _generation) return;

      // Clear first so a day with no quote can't leave a stale one behind.
      await _notifications.cancelQuoteNotifications();
      final l10n = lookupAppLocalizations(Locale(_bangla ? 'bn' : 'en'));
      for (var slot = 0; slot < times.length; slot++) {
        final quote = quotes[slot];
        if (quote == null) continue;
        if (generation != _generation) return;
        final text = dailyQuoteNotificationText(l10n, quote, bangla: _bangla);
        await _notifications.scheduleQuoteNotification(
          slot: slot,
          when: times[slot],
          title: text.title,
          body: text.body,
        );
      }
      _lastScheduledKey = key;
      _lastScheduledAt = DateTime.now();
    } catch (e) {
      // Offline, or a Firestore hiccup. Whatever is already scheduled stays,
      // and nothing is marked done, so the next launch/resume tries again.
      debugPrint('Daily quote schedule refresh failed: $e');
    }
  }

  /// Removes every scheduled daily quote without touching the saved choice -
  /// used on logout, so a signed-out device isn't nudged into a login wall,
  /// and when the user turns the notification off.
  Future<void> cancelScheduled() async {
    _generation++;
    _lastScheduledKey = null;
    _lastScheduledAt = null;
    await _notifications.cancelQuoteNotifications();
  }
}
