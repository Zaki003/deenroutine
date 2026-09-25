import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/prayer_log.dart';
import '../services/firestore_service.dart';
import '../utils/prayer_waqt.dart';

/// Kinds of error [PrayerLogProvider] can surface, localized by
/// `prayerLogErrorMessage` - providers stay `AppLocalizations`-free.
enum PrayerLogErrorType { syncFailed, saveFailed }

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
  Future<bool> setStatus(String prayerKey, PrayerStatus? status) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _service.setPrayerStatus(uid, prayerDay, prayerKey, status);
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
