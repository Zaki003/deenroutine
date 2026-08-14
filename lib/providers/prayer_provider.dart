import 'package:flutter/foundation.dart';
import '../services/prayer_service.dart';

class PrayerProvider extends ChangeNotifier {
  final PrayerService _service = PrayerService();

  Map<String, String> _timings = {};
  bool _loading = false;
  PrayerErrorType? _errorType;
  String? _errorDetail;

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

  Future<void> loadPrayerTimes() async {
    _loading = true;
    _errorType = null;
    _errorDetail = null;
    notifyListeners();
    try {
      final position = await _service.getCurrentLocation();
      _timings = await _service.fetchPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
      );
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
}
