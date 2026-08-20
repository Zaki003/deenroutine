import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_service.dart';

class PrayerProvider extends ChangeNotifier {
  final PrayerService _service = PrayerService();

  // Local, on-device cache. Prayer times only need recomputing once a
  // calendar day, and the location barely ever changes between launches —
  // so the common case (same day, same place) should cost zero GPS fixes
  // and zero network calls, not repeat both on every app start.
  static const _prefsDateKey = 'prayer_cache_date';
  static const _prefsTimingsKey = 'prayer_cache_timings';
  static const _prefsLatKey = 'prayer_last_lat';
  static const _prefsLngKey = 'prayer_last_lng';

  Map<String, String> _timings = {};
  bool _loading = false;
  PrayerErrorType? _errorType;
  String? _errorDetail;

  /// Nothing else drives a rebuild as time passes, so without this the
  /// dashboard's prayer card and the Prayer tab only refresh their
  /// countdown whenever something unrelated happens to rebuild that
  /// particular screen (e.g. toggling a habit) — since both screens stay
  /// mounted at once (IndexedStack), they'd drift out of sync with each
  /// other and each show a stale, different-looking countdown. Ticking
  /// here keeps every listener refreshing off the same clock.
  Timer? _countdownTicker;

  PrayerProvider() {
    _countdownTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_timings.isNotEmpty) notifyListeners();
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  Map<String, String> get timings => _timings;
  bool get isLoading => _loading;
  PrayerErrorType? get errorType => _errorType;
  String? get errorDetail => _errorDetail;
  bool get hasError => _errorType != null;

  /// Timings reordered so the next upcoming prayer is first, followed by
  /// the rest in their normal daily order (wrapping past ones to the end).
  /// If every prayer today has already passed, Fajr (tomorrow's first)
  /// leads the list.
  List<MapEntry<String, String>> get orderedTimings {
    if (_timings.isEmpty) return [];
    final entries = _timings.entries.toList();
    final idx = _nextPrayerIndex(entries);
    return [...entries.sublist(idx), ...entries.sublist(0, idx)];
  }

  /// Name of the next prayer to come, e.g. 'Asr'. Null if timings aren't
  /// loaded yet.
  String? get nextPrayerName =>
      orderedTimings.isEmpty ? null : orderedTimings.first.key;

  /// Raw time-of-day string (e.g. `'4:37 PM'`) for the next prayer, or null
  /// if timings aren't loaded yet.
  String? get nextPrayerTime =>
      orderedTimings.isEmpty ? null : orderedTimings.first.value;

  /// Time remaining until the next prayer. If every prayer today has
  /// already passed, this is measured against Fajr tomorrow, so it's always
  /// non-negative once timings are loaded.
  Duration? get timeUntilNextPrayer {
    if (orderedTimings.isEmpty) return null;
    final now = DateTime.now();
    var target = _parseTimeToday(orderedTimings.first.value);
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));
    return target.difference(now);
  }

  int _nextPrayerIndex(List<MapEntry<String, String>> entries) {
    final now = DateTime.now();
    for (var i = 0; i < entries.length; i++) {
      if (_parseTimeToday(entries[i].value).isAfter(now)) return i;
    }
    return 0;
  }

  DateTime _parseTimeToday(String value) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
    final now = DateTime.now();
    if (match == null) return now;
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  /// Loads today's timings the cheapest way available: same-day local
  /// cache first (no GPS, no network), else the last-known location (no
  /// GPS) against the service's own Firestore/Aladhan chain, and only
  /// asks for a fresh GPS fix if this device has never resolved a
  /// location before. Use [updateLocation] to force a fresh GPS read.
  Future<void> loadPrayerTimes() async {
    _loading = true;
    _errorType = null;
    _errorDetail = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _todayKey();

      if (prefs.getString(_prefsDateKey) == todayKey) {
        final cached = _readCachedTimings(prefs);
        if (cached != null) {
          _timings = cached;
          return;
        }
      }

      final savedLat = prefs.getDouble(_prefsLatKey);
      final savedLng = prefs.getDouble(_prefsLngKey);
      double latitude;
      double longitude;
      if (savedLat != null && savedLng != null) {
        latitude = savedLat;
        longitude = savedLng;
      } else {
        final position = await _service.getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
        await prefs.setDouble(_prefsLatKey, latitude);
        await prefs.setDouble(_prefsLngKey, longitude);
      }

      await _fetchAndCache(prefs, latitude, longitude, todayKey);
    } on PrayerException catch (e) {
      _errorType = e.type;
      _errorDetail = e.detail;
    } catch (e) {
      _errorType = PrayerErrorType.unknown;
      _errorDetail = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Explicit "I've travelled" override: re-reads the device's current GPS
  /// location (ignoring whatever was saved), makes it the new sticky
  /// location for future [loadPrayerTimes] calls, and refreshes today's
  /// timings for it. Returns whether it succeeded, for the caller to show
  /// a result message.
  Future<bool> updateLocation() async {
    _loading = true;
    _errorType = null;
    _errorDetail = null;
    notifyListeners();
    try {
      final position = await _service.getCurrentLocation();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsLatKey, position.latitude);
      await prefs.setDouble(_prefsLngKey, position.longitude);
      await _fetchAndCache(prefs, position.latitude, position.longitude, _todayKey());
      return true;
    } on PrayerException catch (e) {
      _errorType = e.type;
      _errorDetail = e.detail;
      return false;
    } catch (e) {
      _errorType = PrayerErrorType.unknown;
      _errorDetail = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAndCache(
    SharedPreferences prefs,
    double latitude,
    double longitude,
    String todayKey,
  ) async {
    _timings = await _service.fetchPrayerTimes(latitude: latitude, longitude: longitude);
    await prefs.setString(_prefsDateKey, todayKey);
    await prefs.setString(_prefsTimingsKey, jsonEncode(_timings));
  }

  /// Rebuilds the map in canonical key order explicitly, rather than
  /// trusting json round-tripping to preserve it, matching the defensive
  /// approach [PrayerService] already takes with Firestore's map fields.
  Map<String, String>? _readCachedTimings(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsTimingsKey);
    if (raw == null) return null;
    final decoded = Map<String, dynamic>.from(jsonDecode(raw));
    return <String, String>{
      'Fajr': decoded['Fajr'],
      'Dhuhr': decoded['Dhuhr'],
      'Asr': decoded['Asr'],
      'Maghrib': decoded['Maghrib'],
      'Isha': decoded['Isha'],
    };
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
