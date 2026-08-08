import 'package:flutter/material.dart';

const Color kBrandGreen = Color(0xFF2E7D32);

class AppTheme {
  static ThemeData get light => ThemeData(
        colorSchemeSeed: kBrandGreen,
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAF7),
      );

  static ThemeData get dark => ThemeData(
        colorSchemeSeed: kBrandGreen,
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      );
}

/// Accent colours the generated [ColorScheme] does not provide: a "success"
/// green, the habit-category hues, and the quiz-result tones.
///
/// Each has one value per brightness. The brand green and the Material
/// `Colors.blue`/`.purple`/`.orange` constants are tuned for dark text on a
/// light surface — on the dark scaffold they read as muddy smudges, and
/// `Colors.green.shade800` on a dark background is close to invisible. The
/// dark variants below are the same hues lightened until they carry roughly
/// 7:1 contrast against `#121212`, matching what the light variants carry
/// against `#F7FAF7`.
///
/// For errors use [ColorScheme.error]; Material already flips that one.
extension AppSemanticColors on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  /// Positive / completed / correct.
  Color get success => _isDark ? const Color(0xFF81C995) : const Color(0xFF1B5E20);

  /// Tinted surface for the daily-quote card and the "correct answer" tile.
  Color get successContainer =>
      _isDark ? const Color(0xFF16311E) : const Color(0xFFE8F5E9);

  /// Text and icons drawn on [successContainer].
  Color get onSuccessContainer =>
      _isDark ? const Color(0xFFB7E3C1) : const Color(0xFF14401A);

  /// Tinted surface for the "wrong answer" tile, paired with [error].
  Color get errorSurface => _isDark
      ? const Color(0xFF3F2022)
      : const Color(0xFFFFEBEE);

  /// Habit category: lifestyle. Also the quiz "excellent" trophy.
  Color get accentAmber => _isDark ? const Color(0xFFFFCA61) : const Color(0xFF9C5D00);

  /// Habit category: learn.
  Color get accentBlue => _isDark ? const Color(0xFF7FB6F5) : const Color(0xFF1565C0);

  /// Habit category: work.
  Color get accentPurple => _isDark ? const Color(0xFFC7A6F0) : const Color(0xFF6A1B9A);

  /// The quiz "keep learning" outcome.
  Color get accentBrown => _isDark ? const Color(0xFFC7A896) : const Color(0xFF6D4C41);

  /// Unfilled portion of a progress ring.
  Color get progressTrack =>
      _isDark ? const Color(0xFF2C312D) : const Color(0xFFE1E8E2);
}
