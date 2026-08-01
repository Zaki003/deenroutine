import 'package:flutter/foundation.dart';
import '../services/prayer_service.dart';

class PrayerProvider extends ChangeNotifier {
  final PrayerService _service = PrayerService();

  Map<String, String> _timings = {};
  bool _loading = false;
  String? _error;

  Map<String, String> get timings => _timings;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> loadPrayerTimes() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final position = await _service.getCurrentLocation();
      _timings = await _service.fetchPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
