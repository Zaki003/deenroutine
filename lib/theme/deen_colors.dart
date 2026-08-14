import 'package:flutter/material.dart';

/// Flat palette for the redesigned UI (ink/teal/gold Islamic aesthetic),
/// mirroring the approved mockup 1:1 rather than going through Material's
/// seeded [ColorScheme] derivation. Screens read these directly, keyed off
/// [Brightness], the same way the mockup's components took a `dark` prop.
class DeenColors {
  DeenColors._();

  static const ink = Color(0xFF0E2B29);
  static const inkSoft = Color(0xFF153F3C);
  static const inkSofter = Color(0xFF1B4B47);
  static const primary = Color(0xFF146356);
  static const primaryLight = Color(0xFF1F8A73);
  static const gold = Color(0xFFC9A24B);
  static const goldSoft = Color(0xFFE4CD8C);
  static const cream = Color(0xFFF6F1E4);
  static const paper = Color(0xFFFFFDF8);
  static const textDark = Color(0xFF16302B);
  static const textMuted = Color(0xFF6B857D);
  static const rust = Color(0xFFA8522F);
  static const green = Color(0xFF3F9142);

  /// Light-mode wash for the quote card and quiz "best score" banner.
  static const creamPanel = Color(0xFFEFE7D2);

  static Color surface(bool dark) => dark ? ink : cream;
  static Color cardBackground(bool dark) => dark ? inkSoft : paper;
  static Color cardBorder(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.06) : primary.withValues(alpha: 0.08);
  static Color panelBackground(bool dark) => dark ? inkSofter : creamPanel;
  static Color primaryText(bool dark) => dark ? paper : textDark;
  static Color dividerLine(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.08) : primary.withValues(alpha: 0.1);
  static Color trackLine(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.14) : primary.withValues(alpha: 0.14);
  static Color outlineFaint(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.18) : primary.withValues(alpha: 0.25);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, ink],
  );
}
