import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/city.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../utils/prayer_labels.dart';
import 'locale_provider.dart' show localePrefsKey;

/// Fixed, small IDs (not hash-derived like habit reminders) since there are
/// only ever exactly 5 of these - easy to keep memorable and guaranteed
/// stable across app versions, unlike a hashCode that could theoretically
/// change if Dart's string hashing algorithm ever did.
const Map<String, int> kPrayerNotificationIds = {
  'Fajr': -101,
  'Dhuhr': -102,
  'Asr': -103,
  'Maghrib': -104,
  'Isha': -105,
};

class PrayerProvider extends ChangeNotifier {
  final PrayerService _service = PrayerService();
  final NotificationService _notifications = NotificationService();

  // Local, on-device cache. Prayer times only need recomputing once a
  // calendar day, and the location barely ever changes between launches —
  // so the common case (same day, same place) should cost zero GPS fixes
  // and zero network calls, not repeat both on every app start.
  static const _prefsDateKey = 'prayer_cache_date';
  static const _prefsTimingsKey = 'prayer_cache_timings';
  static const _prefsLatKey = 'prayer_last_lat';
  static const _prefsLngKey = 'prayer_last_lng';

  /// Whether [_prefsLatKey]/[_prefsLngKey] came from a manually picked city
  /// rather than GPS, and that city's display label — e.g. "Cairo, Egypt".
  /// Purely for showing "what location are we using" in the UI;
  /// [loadPrayerTimes] doesn't care how the saved coordinates got there.
  static const _prefsManualLabelKey = 'prayer_manual_city_label';

  /// Null until the user explicitly picks one in Settings - see
  /// [calculationMethod]/[asrMethod] for the location-based default used
  /// until then.
  static const _prefsMethodKey = 'prayer_calc_method';
  static const _prefsSchoolKey = 'prayer_asr_school';

  /// One bool per prayer key ('prayer_notify_Fajr', etc.), defaulting to
  /// off - absent from prefs until the user first taps a bell.
  static const _prefsNotifyPrefix = 'prayer_notify_';

  Map<String, String> _timings = {};
  bool _loading = false;
  PrayerErrorType? _errorType;
  String? _errorDetail;
  final Map<String, bool> _notifyEnabled = {};
  String? _manualCityLabel;
  double? _lat;
  double? _lng;
  PrayerCalculationMethod? _explicitMethod;
  AsrJuristicMethod? _explicitSchool;

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

  /// Whether the saved lat/lng came from a manually picked city rather than
  /// GPS, and that city's label (e.g. "Cairo, Egypt") for display. Both are
  /// null until the first [loadPrayerTimes] populates them from prefs.
  bool get isManualLocation => _manualCityLabel != null;
  String? get manualCityLabel => _manualCityLabel;

  /// Resolved calculation method: an explicit Settings choice if one exists,
  /// otherwise a location-based smart default (see
  /// [PrayerService.defaultMethodFor]) once a location is known, otherwise
  /// MWL. Recomputes live off [_lat]/[_lng] as long as nothing's been
  /// explicitly chosen, so it keeps tracking a changed location.
  PrayerCalculationMethod get calculationMethod =>
      _explicitMethod ??
      (_lat != null && _lng != null
          ? _service.defaultMethodFor(lat: _lat!, lng: _lng!)
          : PrayerCalculationMethod.mwl);

  /// Same resolution order as [calculationMethod], for the Asr school.
  AsrJuristicMethod get asrMethod =>
      _explicitSchool ??
      (_lat != null && _lng != null
          ? _service.defaultSchoolFor(lat: _lat!, lng: _lng!)
          : AsrJuristicMethod.standard);

  /// Whether an adhan notification is scheduled for [prayerKey] (e.g.
  /// 'Asr'). Off by default until the user taps that prayer's bell.
  bool notifyEnabled(String prayerKey) => _notifyEnabled[prayerKey] ?? false;

  /// Flips [prayerKey]'s notification on/off, persists it, and immediately
  /// re-syncs every prayer's scheduled notification against the current
  /// choices and today's [_timings] - not just this one prayer, since that's
  /// cheap (five local calls, no network) and keeps [_rescheduleAll] as the
  /// single place that logic lives.
  Future<void> toggleNotify(String prayerKey) async {
    final next = !notifyEnabled(prayerKey);
    _notifyEnabled[prayerKey] = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsNotifyPrefix$prayerKey', next);
    await _rescheduleAll();
  }

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
  ///
  /// [requestIfDenied] defaults to `true` (this is also how Retry and
  /// pull-to-refresh call it - both are deliberate taps, so re-prompting is
  /// fine). Pass `false` for any call the user didn't directly trigger -
  /// MainNavScreen's initial load and its app-resume auto-retry both do -
  /// see [PrayerService.getCurrentLocation] for why that matters.
  Future<void> loadPrayerTimes({bool requestIfDenied = true}) async {
    _loading = true;
    _errorType = null;
    _errorDetail = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _todayKey();
      _manualCityLabel = prefs.getString(_prefsManualLabelKey);
      _explicitMethod = _readMethod(prefs);
      _explicitSchool = _readSchool(prefs);
      for (final key in kPrayerNotificationIds.keys) {
        _notifyEnabled[key] = prefs.getBool('$_prefsNotifyPrefix$key') ?? false;
      }

      final savedLat = prefs.getDouble(_prefsLatKey);
      final savedLng = prefs.getDouble(_prefsLngKey);
      if (savedLat != null && savedLng != null) {
        _lat = savedLat;
        _lng = savedLng;
      }

      // method/school are folded into the stamp, so switching either in
      // Settings invalidates today's local cache immediately instead of
      // silently keeping the previous choice's times until the date rolls
      // over - calculationMethod/asrMethod already reflect the values just
      // loaded above.
      if (prefs.getString(_prefsDateKey) == _cacheStamp(todayKey)) {
        final cached = _readCachedTimings(prefs);
        if (cached != null) {
          _timings = cached;
          return;
        }
      }

      double latitude;
      double longitude;
      if (_lat != null && _lng != null) {
        latitude = _lat!;
        longitude = _lng!;
      } else {
        final position =
            await _service.getCurrentLocation(requestIfDenied: requestIfDenied);
        latitude = position.latitude;
        longitude = position.longitude;
        _lat = latitude;
        _lng = longitude;
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

  /// Opens the system settings screen that can actually fix the current
  /// error — app permission settings for a permanent denial, device
  /// location-services settings for GPS being off entirely. No-op for any
  /// other error type (or none), since [loadPrayerTimes] via Retry is the
  /// right action there instead. See [prayerErrorNeedsSettings].
  Future<void> openSettingsForCurrentError() {
    switch (_errorType) {
      case PrayerErrorType.permissionDeniedForever:
        return _service.openAppSettings();
      case PrayerErrorType.locationServicesDisabled:
        return _service.openLocationSettings();
      default:
        return Future.value();
    }
  }

  /// Explicit "I've travelled" override: re-reads the device's current GPS
  /// location (ignoring whatever was saved, including a previously picked
  /// manual city), makes it the new sticky location for future
  /// [loadPrayerTimes] calls, and refreshes today's timings for it. Returns
  /// whether it succeeded, for the caller to show a result message.
  Future<bool> updateLocation() async {
    _loading = true;
    _errorType = null;
    _errorDetail = null;
    notifyListeners();
    try {
      final position = await _service.getCurrentLocation(requestIfDenied: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsLatKey, position.latitude);
      await prefs.setDouble(_prefsLngKey, position.longitude);
      await prefs.remove(_prefsManualLabelKey);
      _manualCityLabel = null;
      _lat = position.latitude;
      _lng = position.longitude;
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

  /// Sets [city] as the sticky location for future [loadPrayerTimes] calls
  /// (no GPS fix involved) and refreshes today's timings for it. Returns
  /// whether it succeeded, for the caller to show a result message.
  Future<bool> setManualCity(City city) async {
    _loading = true;
    _errorType = null;
    _errorDetail = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsLatKey, city.latitude);
      await prefs.setDouble(_prefsLngKey, city.longitude);
      await prefs.setString(_prefsManualLabelKey, city.displayLabel);
      _manualCityLabel = city.displayLabel;
      _lat = city.latitude;
      _lng = city.longitude;
      await _fetchAndCache(prefs, city.latitude, city.longitude, _todayKey());
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
    _timings = await _service.fetchPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      method: calculationMethod,
      school: asrMethod,
    );
    await prefs.setString(_prefsDateKey, _cacheStamp(todayKey));
    await prefs.setString(_prefsTimingsKey, jsonEncode(_timings));
    await _rescheduleAll();
  }

  /// Cancels and re-schedules every prayer's adhan notification against the
  /// current on/off choices and [_timings]. Runs after every fresh fetch (a
  /// new day means new times) and from [toggleNotify] (same times, a
  /// changed choice) - both are cheap, local-only calls, so re-syncing all
  /// five rather than just the one that changed keeps this the single place
  /// that scheduling logic lives.
  ///
  /// Builds notification text via [lookupAppLocalizations] instead of the
  /// usual BuildContext-based lookup: this runs from a background refresh,
  /// with no widget on screen to defer to, and the text has to be baked in
  /// now since the OS shows whatever was scheduled whenever the alarm
  /// actually fires.
  Future<void> _rescheduleAll() async {
    if (_timings.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final locale = Locale(prefs.getString(localePrefsKey) == 'bn' ? 'bn' : 'en');
    final l10n = lookupAppLocalizations(locale);

    for (final entry in kPrayerNotificationIds.entries) {
      final prayerKey = entry.key;
      final id = entry.value;
      await _notifications.cancelReminder(id);
      final timeStr = _timings[prayerKey];
      if (timeStr == null || !notifyEnabled(prayerKey)) continue;
      final name = prayerNameLabel(l10n, prayerKey);
      await _notifications.schedulePrayerNotification(
        id: id,
        title: name,
        body: l10n.prayerNotificationBody(name),
        time: _parseTimeToday(timeStr),
      );
    }
  }

  /// Explicit choice from Settings - persists it and re-fetches today's
  /// timings immediately under the new method, rather than waiting for the
  /// next natural cache miss to notice.
  Future<void> setCalculationMethod(PrayerCalculationMethod method) async {
    _explicitMethod = method;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsMethodKey, method.aladhanCode);
    notifyListeners();
    await _refetchToday();
  }

  /// Same shape as [setCalculationMethod], for the Asr school.
  Future<void> setAsrMethod(AsrJuristicMethod school) async {
    _explicitSchool = school;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsSchoolKey, school.aladhanCode);
    notifyListeners();
    await _refetchToday();
  }

  /// Re-fetches today's timings under whatever [calculationMethod]/[asrMethod]
  /// currently resolve to. No-ops quietly if location isn't known yet -
  /// [loadPrayerTimes] will pick up the new choice whenever it next runs.
  Future<void> _refetchToday() async {
    if (_lat == null || _lng == null) return;
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await _fetchAndCache(prefs, _lat!, _lng!, _todayKey());
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

  PrayerCalculationMethod? _readMethod(SharedPreferences prefs) {
    final code = prefs.getInt(_prefsMethodKey);
    return code == null ? null : PrayerCalculationMethod.fromCode(code);
  }

  AsrJuristicMethod? _readSchool(SharedPreferences prefs) {
    final code = prefs.getInt(_prefsSchoolKey);
    return code == null ? null : AsrJuristicMethod.fromCode(code);
  }

  /// Folds the resolved method/school into the same-day cache key - see
  /// their use in [loadPrayerTimes] and [_fetchAndCache].
  String _cacheStamp(String todayKey) =>
      '$todayKey|${calculationMethod.aladhanCode}|${asrMethod.aladhanCode}';

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
