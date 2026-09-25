import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../models/prayer_log.dart';
import '../services/firestore_service.dart';
import '../services/habit_notification_scheduler.dart';
import '../services/notification_service.dart';
import '../services/prayer_check_in_scheduler.dart';
import '../utils/daily_quote_notification.dart';
import '../utils/daily_quote_schedule.dart';
import '../utils/prayer_check_in_plan.dart';
import '../utils/prayer_labels.dart';
import 'habit_provider.dart';
import 'prayer_log_provider.dart';
import 'prayer_provider.dart';

/// The user's notification choices, persisted on the device like
/// [ThemeProvider]'s, and the scheduling that acts on them.
///
/// Every switch is on by default and can be turned off: the daily
/// ayah/hadith, the streak reminder, the Friday summary, the come-back
/// message, and the encouraging wording of habit reminders (which falls back
/// to the plain "Time for: ..." line when off). The one exception is prayer
/// check-ins (Android only), which are opt-in: up to five a day is a lot to
/// start sending unasked.
///
/// Two independent schedules live here. The daily quote is a rolling window
/// of the next [NotificationService.quoteNotificationSlots] days. Everything
/// tied to habits is delegated to [HabitNotificationScheduler], which is
/// rebuilt whenever a habit or a setting changes. Both are topped up on every
/// launch and resume, and only run out if the app goes unopened for about a
/// week.
class NotificationSettingsProvider extends ChangeNotifier {
  static const _quoteEnabledKey = 'daily_quote_notify_enabled';
  static const _quoteHourKey = 'daily_quote_notify_hour';
  static const _quoteMinuteKey = 'daily_quote_notify_minute';
  static const _encouragingKey = 'reminders_encouraging';
  static const _streakEnabledKey = 'streak_nudge_enabled';
  static const _streakHourKey = 'streak_nudge_hour';
  static const _streakMinuteKey = 'streak_nudge_minute';
  static const _weeklyKey = 'weekly_summary_enabled';
  static const _comebackKey = 'comeback_enabled';
  static const _checkInEnabledKey = 'prayer_checkin_enabled';
  static const _checkInPrayersKey = 'prayer_checkin_prayers';
  static const _checkInDelayKey = 'prayer_checkin_delay_minutes';

  static const _defaultQuoteHour = 7;
  static const _defaultStreakHour = 20;
  static const _refreshEvery = Duration(hours: 6);
  static const _habitDebounce = Duration(seconds: 2);

  final NotificationService _notifications = NotificationService();
  final FirestoreService _firestore = FirestoreService();
  late final HabitNotificationScheduler _habitScheduler =
      HabitNotificationScheduler(_notifications);
  late final PrayerCheckInScheduler _checkInScheduler =
      PrayerCheckInScheduler(_notifications);

  bool _loaded = false;
  bool _quoteEnabled = true;
  int _quoteHour = _defaultQuoteHour;
  int _quoteMinute = 0;
  bool _encouragingReminders = true;
  bool _streakNudge = true;
  int _streakHour = _defaultStreakHour;
  int _streakMinute = 0;
  bool _weeklySummary = true;
  bool _comeback = true;
  bool _checkInEnabled = false;
  Set<String> _checkInPrayers = {...PrayerLog.prayerKeys};
  int _checkInDelay = defaultCheckInDelayMinutes;
  bool _bangla = false;

  late final Future<void> _loading;

  // ---- Daily quote schedule state
  // Bumped by anything that supersedes an in-flight run (a newer run, a
  // cancel), so the older one stops before sending another schedule call
  // rather than resurrecting notifications the user just turned off.
  int _quoteGeneration = 0;
  String? _lastQuoteKey;
  DateTime? _lastQuoteAt;

  // ---- Habit schedule state
  HabitProvider? _habits;
  Timer? _habitDebounceTimer;
  bool _habitRunning = false;
  bool _habitRerun = false;
  bool _habitRerunForce = false;
  int _habitGeneration = 0;
  String? _lastHabitSignature;
  DateTime? _lastHabitAt;

  // ---- Prayer check-in schedule state (same one-run-at-a-time shape)
  PrayerProvider? _prayer;
  PrayerLogProvider? _prayerLogs;
  Timer? _checkInDebounceTimer;
  bool _checkInRunning = false;
  bool _checkInRerun = false;
  bool _checkInRerunForce = false;
  int _checkInGeneration = 0;
  String? _lastCheckInSignature;

  bool get loaded => _loaded;
  bool get quoteEnabled => _quoteEnabled;
  int get quoteHour => _quoteHour;
  int get quoteMinute => _quoteMinute;
  bool get encouragingReminders => _encouragingReminders;
  bool get streakNudge => _streakNudge;
  int get streakHour => _streakHour;
  int get streakMinute => _streakMinute;
  bool get weeklySummary => _weeklySummary;
  bool get comeback => _comeback;
  bool get checkInEnabled => _checkInEnabled;
  Set<String> get checkInPrayers => _checkInPrayers;
  int get checkInDelayMinutes => _checkInDelay;

  /// Background notification buttons only work reliably on Android so far.
  bool get checkInsSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  NotificationSettingsProvider() {
    _loading = _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _quoteEnabled = prefs.getBool(_quoteEnabledKey) ?? true;
    _quoteHour = prefs.getInt(_quoteHourKey) ?? _defaultQuoteHour;
    _quoteMinute = prefs.getInt(_quoteMinuteKey) ?? 0;
    _encouragingReminders = prefs.getBool(_encouragingKey) ?? true;
    _streakNudge = prefs.getBool(_streakEnabledKey) ?? true;
    _streakHour = prefs.getInt(_streakHourKey) ?? _defaultStreakHour;
    _streakMinute = prefs.getInt(_streakMinuteKey) ?? 0;
    _weeklySummary = prefs.getBool(_weeklyKey) ?? true;
    _comeback = prefs.getBool(_comebackKey) ?? true;
    _checkInEnabled = prefs.getBool(_checkInEnabledKey) ?? false;
    final savedPrayers = prefs.getStringList(_checkInPrayersKey);
    _checkInPrayers = savedPrayers == null
        ? {...PrayerLog.prayerKeys}
        : {...savedPrayers.where(PrayerLog.prayerKeys.contains)};
    final delay = prefs.getInt(_checkInDelayKey);
    _checkInDelay = checkInDelayChoices.contains(delay) ? delay! : defaultCheckInDelayMinutes;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// Asked in context, at the moment the user opts in to something, rather
  /// than at launch - a no-op when already granted (or below Android 13).
  Future<void> _askPermission() async {
    await _notifications.requestPermission();
  }

  // ---------------- Daily ayah / hadith ----------------

  Future<void> setQuoteEnabled(bool enabled) async {
    await _loading;
    _quoteEnabled = enabled;
    notifyListeners();
    await _saveBool(_quoteEnabledKey, enabled);
    if (enabled) {
      await _askPermission();
      await refreshSchedule(force: true);
    } else {
      await _cancelQuote();
    }
  }

  Future<void> setQuoteTime(int hour, int minute) async {
    await _loading;
    _quoteHour = hour;
    _quoteMinute = minute;
    notifyListeners();
    await _saveInt(_quoteHourKey, hour);
    await _saveInt(_quoteMinuteKey, minute);
    if (_quoteEnabled) await refreshSchedule(force: true);
  }

  /// Rebuilds the rolling window of scheduled quotes. Skipped when nothing
  /// changed and it was done recently, so calling it on every app resume
  /// stays cheap.
  Future<void> refreshSchedule({bool force = false}) async {
    await _loading;
    if (!_quoteEnabled) return;

    final key = '$_quoteHour:$_quoteMinute:$_bangla';
    final last = _lastQuoteAt;
    if (!force &&
        key == _lastQuoteKey &&
        last != null &&
        DateTime.now().difference(last) < _refreshEvery) {
      return;
    }

    final generation = ++_quoteGeneration;
    try {
      final times = upcomingDailyTimes(
        DateTime.now(),
        hour: _quoteHour,
        minute: _quoteMinute,
        count: NotificationService.quoteNotificationSlots,
      );
      final quotes = await _firestore.getDailyQuotesFor(times);
      if (generation != _quoteGeneration) return;

      // Clear first so a day with no quote can't leave a stale one behind.
      await _notifications.cancelQuoteNotifications();
      final l10n = lookupAppLocalizations(Locale(_bangla ? 'bn' : 'en'));
      for (var slot = 0; slot < times.length; slot++) {
        final quote = quotes[slot];
        if (quote == null) continue;
        if (generation != _quoteGeneration) return;
        final text = dailyQuoteNotificationText(l10n, quote, bangla: _bangla);
        await _notifications.scheduleQuoteNotification(
          slot: slot,
          when: times[slot],
          title: text.title,
          body: text.body,
        );
      }
      _lastQuoteKey = key;
      _lastQuoteAt = DateTime.now();
    } catch (e) {
      // Offline, or a Firestore hiccup. Whatever is already scheduled stays,
      // and nothing is marked done, so the next launch/resume tries again.
      debugPrint('Daily quote schedule refresh failed: $e');
    }
  }

  Future<void> _cancelQuote() async {
    _quoteGeneration++;
    _lastQuoteKey = null;
    _lastQuoteAt = null;
    await _notifications.cancelQuoteNotifications();
  }

  // ---------------- Habit reminders and nudges ----------------

  Future<void> setEncouragingReminders(bool value) async {
    await _loading;
    _encouragingReminders = value;
    notifyListeners();
    await _saveBool(_encouragingKey, value);
    await _runHabitSchedule(force: true);
  }

  Future<void> setStreakNudge(bool value) async {
    await _loading;
    _streakNudge = value;
    notifyListeners();
    await _saveBool(_streakEnabledKey, value);
    if (value) await _askPermission();
    await _runHabitSchedule(force: true);
  }

  Future<void> setStreakNudgeTime(int hour, int minute) async {
    await _loading;
    _streakHour = hour;
    _streakMinute = minute;
    notifyListeners();
    await _saveInt(_streakHourKey, hour);
    await _saveInt(_streakMinuteKey, minute);
    if (_streakNudge) await _runHabitSchedule(force: true);
  }

  Future<void> setWeeklySummary(bool value) async {
    await _loading;
    _weeklySummary = value;
    notifyListeners();
    await _saveBool(_weeklyKey, value);
    if (value) await _askPermission();
    await _runHabitSchedule(force: true);
  }

  Future<void> setComeback(bool value) async {
    await _loading;
    _comeback = value;
    notifyListeners();
    await _saveBool(_comebackKey, value);
    if (value) await _askPermission();
    await _runHabitSchedule(force: true);
  }

  /// Called on launch and resume. Habits may not have loaded yet on the very
  /// first call - [onHabitsChanged] covers the moment they do.
  Future<void> refreshHabitSchedule(HabitProvider habits) {
    _habits = habits;
    return _runHabitSchedule();
  }

  /// Called whenever [HabitProvider] notifies. Debounced, since one tap can
  /// produce several updates, and most updates change nothing a notification
  /// depends on (see [_habitSignature]).
  void onHabitsChanged(HabitProvider habits) {
    _habits = habits;
    _habitDebounceTimer?.cancel();
    _habitDebounceTimer = Timer(_habitDebounce, _runHabitSchedule);
  }

  /// Fed from [LocaleProvider] (see app.dart) so scheduled text follows a
  /// language switch instead of staying in the old language for up to a week.
  /// Runs during a build, so it must not notify listeners synchronously -
  /// both refreshes only do that after their first await.
  void onLocaleChanged(bool bangla) {
    if (_bangla == bangla) return;
    _bangla = bangla;
    if (_quoteEnabled) refreshSchedule();
    if (_habits != null) _runHabitSchedule();
    if (_prayer != null) _runCheckIns();
  }

  NotificationPrefs get _habitPrefs => NotificationPrefs(
        encouragingReminders: _encouragingReminders,
        streakNudge: _streakNudge,
        streakHour: _streakHour,
        streakMinute: _streakMinute,
        weeklySummary: _weeklySummary,
        comeback: _comeback,
      );

  /// Everything a habit notification's content or timing depends on, and the
  /// date (the window rolls forward at midnight). If it hasn't changed since
  /// the last run, there's nothing to redo.
  String _habitSignature(List<Habit> habits, NotificationPrefs prefs, DateTime now) {
    final b = StringBuffer('${now.year}-${now.month}-${now.day}|$_bangla|')
      ..write(prefs.signature);
    for (final h in habits) {
      b
        ..write('|${h.habitId}:${h.title}:${h.frequency.index}:')
        ..write('${h.trackingType.index}:${h.selectedDays.join(',')}:')
        ..write('${h.dueDate?.millisecondsSinceEpoch}:')
        ..write('${h.reminderHour}:${h.reminderMinute}:')
        ..write('${h.isCompletedToday ? 1 : 0}${h.completed ? 1 : 0}');
    }
    return b.toString();
  }

  /// One run at a time: a request that arrives mid-run is folded into a single
  /// rerun afterwards, so overlapping runs never interleave their schedule
  /// calls.
  Future<void> _runHabitSchedule({bool force = false}) async {
    await _loading;
    if (_habitRunning) {
      _habitRerun = true;
      _habitRerunForce = _habitRerunForce || force;
      return;
    }
    _habitRunning = true;
    try {
      var forceThis = force;
      do {
        _habitRerun = false;
        final generation = _habitGeneration;
        final habitProvider = _habits;
        if (habitProvider == null || !habitProvider.hasLoadedOnce) break;

        final habits = List<Habit>.of(habitProvider.habits);
        final prefs = _habitPrefs;
        final now = DateTime.now();
        final signature = _habitSignature(habits, prefs, now);
        final last = _lastHabitAt;
        final fresh = last != null && now.difference(last) < _refreshEvery;
        if (!forceThis && signature == _lastHabitSignature && fresh) break;

        await _habitScheduler.reschedule(
          habits: habits,
          prefs: prefs,
          l10n: lookupAppLocalizations(Locale(_bangla ? 'bn' : 'en')),
          isCurrent: () => generation == _habitGeneration,
          streakAsOf: habitProvider.streakAsOf,
          weekFor: habitProvider.weekFor,
          now: now,
        );
        if (generation == _habitGeneration) {
          _lastHabitSignature = signature;
          _lastHabitAt = now;
        }
        forceThis = _habitRerunForce;
        _habitRerunForce = false;
      } while (_habitRerun);
    } catch (e) {
      debugPrint('Habit notification schedule failed: $e');
    } finally {
      _habitRunning = false;
    }
  }

  // ---------------- Prayer check-ins ----------------

  Future<void> setCheckInEnabled(bool value) async {
    await _loading;
    _checkInEnabled = value;
    notifyListeners();
    await _saveBool(_checkInEnabledKey, value);
    if (value) await _askPermission();
    await _runCheckIns(force: true);
  }

  Future<void> toggleCheckInPrayer(String prayerKey) async {
    await _loading;
    final next = {..._checkInPrayers};
    if (!next.remove(prayerKey)) next.add(prayerKey);
    _checkInPrayers = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _checkInPrayersKey,
      [for (final k in PrayerLog.prayerKeys) if (next.contains(k)) k],
    );
    await _runCheckIns(force: true);
  }

  Future<void> setCheckInDelay(int minutes) async {
    await _loading;
    _checkInDelay = minutes;
    notifyListeners();
    await _saveInt(_checkInDelayKey, minutes);
    await _runCheckIns(force: true);
  }

  /// Called on launch and resume.
  Future<void> refreshPrayerCheckIns(PrayerProvider prayer, PrayerLogProvider logs) {
    _prayer = prayer;
    _prayerLogs = logs;
    return _runCheckIns();
  }

  /// Called whenever prayer times or today's prayer log change - including
  /// [PrayerProvider]'s 30-second tick, which is what notices the prayer day
  /// rolling over. Debounced; most calls change nothing (see [_runCheckIns]).
  void onPrayerChanged(PrayerProvider prayer, PrayerLogProvider logs) {
    _prayer = prayer;
    _prayerLogs = logs;
    _checkInDebounceTimer?.cancel();
    _checkInDebounceTimer = Timer(_habitDebounce, _runCheckIns);
  }

  Future<void> _runCheckIns({bool force = false}) async {
    await _loading;
    if (!checkInsSupported) return;
    if (_checkInRunning) {
      _checkInRerun = true;
      _checkInRerunForce = _checkInRerunForce || force;
      return;
    }
    _checkInRunning = true;
    try {
      var forceThis = force;
      do {
        _checkInRerun = false;
        final generation = _checkInGeneration;
        if (!_checkInEnabled || _checkInPrayers.isEmpty) {
          if (_lastCheckInSignature != 'off') await _checkInScheduler.cancelAll();
          _lastCheckInSignature = 'off';
          break;
        }
        final prayer = _prayer;
        final logs = _prayerLogs;
        if (prayer == null || logs == null || prayer.timings.isEmpty || prayer.sunrise == null) break;

        final lang = _bangla ? 'bn' : 'en';
        final logged = {
          for (final k in PrayerLog.prayerKeys)
            if (logs.statusFor(k) != null) k,
        };
        // Everything the plan depends on except the clock: a check-in time
        // passing needs no rebuild, the notification just fires.
        final signature = [
          PrayerLog.dayKey(logs.prayerDay),
          lang,
          _checkInDelay,
          [for (final k in PrayerLog.prayerKeys) if (_checkInPrayers.contains(k)) k].join(','),
          prayer.timings.values.join(','),
          prayer.sunrise,
          logged.join(','),
          logs.isAvailable,
        ].join('|');
        if (!forceThis && signature == _lastCheckInSignature) break;

        final l10n = lookupAppLocalizations(Locale(lang));
        final timeFormat = DateFormat.jm(lang);
        final plan = planPrayerCheckIns(
          now: DateTime.now(),
          timings: prayer.timings,
          sunrise: prayer.sunrise,
          delay: Duration(minutes: _checkInDelay),
          prayers: _checkInPrayers,
          loggedToday: logged,
          lang: lang,
          text: (key, lateEnd) {
            final name = prayerNameLabel(l10n, key);
            return (
              title: l10n.prayerCheckInTitle(name),
              body: l10n.prayerCheckInBody(name, timeFormat.format(lateEnd)),
            );
          },
        );
        await _checkInScheduler.apply(plan, l10n, isCurrent: () => generation == _checkInGeneration);
        if (generation == _checkInGeneration) _lastCheckInSignature = signature;
        forceThis = _checkInRerunForce;
        _checkInRerunForce = false;
      } while (_checkInRerun);
    } catch (e) {
      debugPrint('Prayer check-in schedule failed: $e');
    } finally {
      _checkInRunning = false;
    }
  }

  // ---------------- Logout ----------------

  /// Removes every scheduled notification this provider owns without touching
  /// the saved choices - used on logout, so a signed-out device isn't nudged
  /// into a login wall (or reminded about someone else's habits). Signing back
  /// in rebuilds everything.
  Future<void> cancelScheduled() async {
    _habitDebounceTimer?.cancel();
    _habitGeneration++;
    _lastHabitSignature = null;
    _lastHabitAt = null;
    _habits = null;
    _checkInDebounceTimer?.cancel();
    _checkInGeneration++;
    _lastCheckInSignature = null;
    _prayer = null;
    _prayerLogs = null;
    await Future.wait([_cancelQuote(), _habitScheduler.cancelAll(), _checkInScheduler.cancelAll()]);
  }
}
