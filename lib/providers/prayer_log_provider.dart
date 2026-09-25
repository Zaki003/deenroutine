import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/prayer_log.dart';
import '../services/firestore_service.dart';
import '../utils/prayer_stats.dart';
import '../utils/prayer_waqt.dart';

/// Kinds of error [PrayerLogProvider] can surface, localized by
/// `prayerLogErrorMessage` - providers stay `AppLocalizations`-free.
enum PrayerLogErrorType { syncFailed, saveFailed, historyFailed }

/// Which of the current prayer day's five prayers have been logged, and how.
/// Kept apart from [PrayerProvider] (timings, location, alarms), which it
/// follows through a proxy provider for the timings that decide each
/// prayer's waqt - see [updateTimings].
class PrayerLogProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  String? _uid;
  DateTime? _subscribedDay;
  StreamSubscription<PrayerLog?>? _sub;
  PrayerLog? _log;

  Map<String, String> _timings = const {};
  String? _sunrise;

  /// How far back the Profile's stats load. 30 days feed the percentages and
  /// grid; the rest only lets a streak run past a month before it shows as
  /// "90+".
  static const historyDays = 90;

  // Past records for the stats, fetched once per prayer day - today's comes
  // from the live listener instead, so logging a prayer updates the stats
  // without another fetch.
  Map<String, PrayerLog> _history = {};
  DateTime? _historyDay;
  bool _historyWanted = false;
  bool _historyLoading = false;

  PrayerLogErrorType? _errorType;
  String? _errorDetail;
  PrayerLogErrorType? get errorType => _errorType;
  String? get errorDetail => _errorDetail;
  bool get hasError => _errorType != null;

  /// Fed by the proxy provider every time [PrayerProvider] notifies, which
  /// includes its 30-second countdown tick - so this is also what notices the
  /// prayer day rolling over at Fajr and moves the listener to the new day.
  /// Runs during a build, so it must not notify synchronously.
  void updateTimings(Map<String, String> timings, String? sunrise) {
    _timings = timings;
    _sunrise = sunrise;
    _resubscribeIfDayChanged();
  }

  void listen(String uid) {
    if (_uid == uid && _sub != null) return;
    _uid = uid;
    _subscribedDay = null;
    _resubscribeIfDayChanged();
  }

  /// Call when the signed-in session ends, mirroring
  /// [HabitProvider.stopListening].
  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    _subscribedDay = null;
    _log = null;
    _history = {};
    _historyDay = null;
    _historyWanted = false;
    _errorType = null;
    _errorDetail = null;
    // Deferred for the same reason as LearnProvider.stopListening: callers
    // run this from dispose(), while the widget tree is locked.
    Future.microtask(notifyListeners);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// The prayer day now belongs to: yesterday until today's Fajr begins.
  DateTime get prayerDay => currentPrayerDay(DateTime.now(), _timings['Fajr']);

  /// Whether [prayerDay] is an earlier calendar date than today, i.e. it's
  /// between midnight and Fajr.
  bool get prayerDayIsYesterday {
    final now = DateTime.now();
    return prayerDay.isBefore(DateTime(now.year, now.month, now.day));
  }

  Map<String, PrayerWaqtWindow>? get _windows =>
      _timings.isEmpty ? null : prayerWindowsFor(prayerDay, _timings, _sunrise);

  PrayerWaqtWindow? windowFor(String prayerKey) => _windows?[prayerKey];

  /// Tracking needs [PrayerProvider.sunrise] too, so it stays off until
  /// timings including it have loaded.
  bool get isAvailable => _uid != null && _windows != null;

  PrayerStatus? statusFor(String prayerKey) {
    final log = _log;
    if (log == null || log.day != PrayerLog.dayKey(prayerDay)) return null;
    return log.statusFor(prayerKey);
  }

  int get prayedCount => PrayerLog.prayerKeys.where((k) => statusFor(k)?.counted ?? false).length;

  bool canLog(String prayerKey) => windowFor(prayerKey)?.hasStarted(DateTime.now()) ?? false;

  /// One-tap log: works out on time / late / qada from the clock. Only
  /// right when logging straight after praying - a later correction goes
  /// through [setStatus]. Returns whether the write succeeded.
  Future<bool> logNow(String prayerKey) {
    final status = windowFor(prayerKey)?.statusAt(DateTime.now());
    if (status == null) return Future.value(false);
    return setStatus(prayerKey, status);
  }

  /// Sets or, with null, clears [prayerKey] on the current prayer day.
  Future<bool> setStatus(String prayerKey, PrayerStatus? status) =>
      _write({prayerKey: status});

  /// Marks every prayer of the current prayer day that hasn't been logged as
  /// prayed as excused, in one tap - including ones whose time hasn't
  /// started. Prayers already logged as prayed keep their status.
  Future<bool> excuseDay() => _write({
        for (final key in PrayerLog.prayerKeys)
          if (!(statusFor(key)?.counted ?? false)) key: PrayerStatus.excused,
      });

  /// Loads the past [historyDays] for [stats], once per prayer day. Safe to
  /// call on every Profile build; once it's been asked for, it reloads by
  /// itself when the prayer day rolls over.
  Future<void> loadHistory() async {
    _historyWanted = true;
    final uid = _uid;
    final day = prayerDay;
    if (uid == null || _timings.isEmpty || _historyLoading || _historyDay == day) return;
    _historyLoading = true;
    try {
      final from = DateTime(day.year, day.month, day.day - (historyDays - 1));
      final logs = await _service.getPrayerLogsSince(uid, from);
      if (_uid != uid) return;
      _history = {for (final l in logs) l.day: l};
      _historyDay = day;
      if (_errorType == PrayerLogErrorType.historyFailed) {
        _errorType = null;
        _errorDetail = null;
      }
      notifyListeners();
    } catch (e) {
      _setError(PrayerLogErrorType.historyFailed, e.toString());
    } finally {
      _historyLoading = false;
    }
  }

  /// Null until [loadHistory] has finished for the current prayer day, and
  /// while nothing has ever been logged.
  PrayerStats? get stats {
    final day = _historyDay;
    if (day == null || day != prayerDay) return null;
    final logs = {..._history};
    final today = _log;
    if (today != null && today.day == PrayerLog.dayKey(day)) logs[today.day] = today;
    if (logs.isEmpty) return null;
    return computePrayerStats(
      today: day,
      logsByDay: logs,
      oldestLoaded: DateTime(day.year, day.month, day.day - (historyDays - 1)),
      startedToday: {for (final k in PrayerLog.prayerKeys) if (canLog(k)) k},
    );
  }

  Future<bool> _write(Map<String, PrayerStatus?> statuses) async {
    final uid = _uid;
    if (uid == null) return false;
    if (statuses.isEmpty) return true;
    try {
      await _service.setPrayerStatuses(uid, prayerDay, statuses);
      if (_errorType == PrayerLogErrorType.saveFailed) _clearError();
      return true;
    } catch (e) {
      _setError(PrayerLogErrorType.saveFailed, e.toString());
      return false;
    }
  }

  void _resubscribeIfDayChanged() {
    final uid = _uid;
    if (uid == null || _timings.isEmpty) return;
    final day = prayerDay;
    // Covers the Profile asking before timings had loaded, a new prayer day
    // (yesterday's live record is history now), and retrying a failed load
    // on the next tick. Deferred since this runs during a build.
    if (_historyWanted && _historyDay != day && !_historyLoading) Future.microtask(loadHistory);
    if (_sub != null && day == _subscribedDay) return;

    _sub?.cancel();
    _subscribedDay = day;
    _sub = _service.watchPrayerLog(uid, day).listen(
      (log) {
        _log = log;
        if (_errorType == PrayerLogErrorType.syncFailed) {
          _errorType = null;
          _errorDetail = null;
        }
        notifyListeners();
      },
      onError: (Object e) {
        if (!_service.isSignedInAs(uid)) {
          // Signed out or deleted mid-listen - see FirestoreService.isSignedInAs.
          _sub?.cancel();
          _sub = null;
          return;
        }
        _setError(PrayerLogErrorType.syncFailed, e.toString());
        _sub?.cancel();
        _sub = null;
        Future.delayed(const Duration(seconds: 3), () {
          if (_uid == uid) _resubscribeIfDayChanged();
        });
      },
    );
  }

  void _setError(PrayerLogErrorType type, String detail) {
    _errorType = type;
    _errorDetail = detail;
    notifyListeners();
  }

  void _clearError() {
    _errorType = null;
    _errorDetail = null;
    notifyListeners();
  }
}
