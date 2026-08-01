import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings module: theme toggle (light/dark), persisted locally so it
/// survives app restarts (backed by SharedPreferences rather than the
/// `Settings` Firestore collection, since it's a device-level UI
/// preference — swap the storage layer out for Firestore if you want it
/// to sync across a user's devices instead).
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  Future<void> toggleDarkMode(bool enableDark) {
    return setThemeMode(enableDark ? ThemeMode.dark : ThemeMode.light);
  }
}