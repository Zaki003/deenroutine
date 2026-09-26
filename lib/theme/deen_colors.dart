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
  static Color textMuted(bool dark) => dark ? const Color(0xFF96ACA5) : const Color(0xFF4A5E57);
  static const rust = Color(0xFFA8522F);
  static const rustLight = Color(0xFFD08F6E);
  static const green = Color(0xFF3F9142);

  /// Prayer-log states. Qada gets its own blue so it never reads as a shade
  /// of late; "not prayed" deliberately has no colour of its own (see the
  /// Prayer screen) so a missed prayer never shows up as a red mark.
  ///
  /// Each is at least 3:1 against [cardBackground] in its own theme (WCAG's
  /// bar for chart marks), which is why they aren't simply [primaryLight]
  /// and [gold]: those measured 2.7:1 in dark and 2.4:1 in light. Draw an
  /// icon on one in its matching `on...` colour.
  static Color prayerOnTime(bool dark) => statsFill(dark);
  static Color onPrayerOnTime(bool dark) => dark ? ink : Colors.white;
  static Color prayerLate(bool dark) => dark ? gold : const Color(0xFFA8832F);
  static const onPrayerLate = ink;
  static Color prayerQada(bool dark) => dark ? const Color(0xFF5B8FD6) : const Color(0xFF2F6DB5);

  /// Empty grid squares and bar tracks in the prayer stats: a little
  /// stronger than [outlineFaint] so the grid's shape reads, but kept well
  /// below the data colours so "nothing here" never looks like a mark.
  static Color prayerEmpty(bool dark) => statsEmpty(dark);

  /// The done / empty pair every stats chart uses (prayer and habit
  /// insights), measured the same way: [statsFill] is at least 3:1 against
  /// [cardBackground] in both themes, [statsEmpty] deliberately well below.
  static Color statsFill(bool dark) => dark ? const Color(0xFF34A88D) : primary;
  static Color statsEmpty(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.22) : primary.withValues(alpha: 0.32);

  /// A neutral line that still has to be seen - a not-yet-earned badge's
  /// ring, a zero-day bar, a day still to come - at 3:1 against
  /// [cardBackground] (3.2:1 light, 3.4:1 dark), where [outlineFaint]
  /// measures about 1.5-1.7:1 and is only fit for decoration.
  static Color statsOutline(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.42) : primary.withValues(alpha: 0.65);

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
