import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

/// Holds the user's opt-in choice for usage analytics — off by default,
/// persisted locally like [ThemeProvider]'s theme choice. [main] disables
/// Firebase Analytics collection unconditionally before this loads, so
/// there's never a window where collection runs ahead of a known choice;
/// this only ever turns it on, never assumes it's already off.
class AnalyticsProvider extends ChangeNotifier {
  static const _prefsKey = 'analytics_enabled';

  final AnalyticsService _service = AnalyticsService();

  bool _enabled = false;
  bool get enabled => _enabled;

  AnalyticsProvider() {
    _loadSavedChoice();
  }

  Future<void> _loadSavedChoice() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? false;
    if (_enabled) await _service.setEnabled(true);
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    notifyListeners();

    await _service.setEnabled(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}
