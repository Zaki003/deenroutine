import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings module: app language (English/Bangla), persisted locally so it
/// survives app restarts. Same storage approach as [ThemeProvider] — a
/// device-level UI preference in SharedPreferences rather than Firestore.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool get isBangla => _locale.languageCode == 'bn';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'bn') {
      _locale = const Locale('bn');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
