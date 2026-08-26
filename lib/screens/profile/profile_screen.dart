import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/text_format.dart';
import '../../widgets/deen_card.dart';

/// FR-03: Profile management, and Settings collection (theme, prayer method).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final user = auth.appUser;
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = capitalizeWords(user?.name ?? '');

    return ColoredBox(
      color: DeenColors.surface(dark),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: DeenColors.primary,
                child: Text(
                  (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DeenColors.primaryText(dark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.profilePreferencesLabel),
          const SizedBox(height: 8),
          DeenCard(
            dark: dark,
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appearanceTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DeenColors.primaryText(dark),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: dark ? DeenColors.ink : DeenColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _AppearanceOption(
                        icon: Icons.light_mode_rounded,
                        label: l10n.appearanceLight,
                        selected: themeProvider.themeMode == ThemeMode.light,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                      ),
                      _AppearanceOption(
                        icon: Icons.dark_mode_rounded,
                        label: l10n.appearanceDark,
                        selected: themeProvider.themeMode == ThemeMode.dark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      ),
                      _AppearanceOption(
                        icon: Icons.brightness_auto_rounded,
                        label: l10n.appearanceSystem,
                        selected: themeProvider.themeMode == ThemeMode.system,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DeenCard(
            dark: dark,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.languageTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DeenColors.primaryText(dark),
                  ),
                ),
                _LanguageRow(
                  label: l10n.languageEnglish,
                  selected: !localeProvider.isBangla,
                  dark: dark,
                  onTap: () => localeProvider.setLocale(const Locale('en')),
                ),
                _LanguageRow(
                  label: l10n.languageBangla,
                  selected: localeProvider.isBangla,
                  dark: dark,
                  onTap: () => localeProvider.setLocale(const Locale('bn')),
                ),
              ],
            ),
          ),
          _SectionLabel(l10n.profileAccountLabel),
          const SizedBox(height: 8),
          DeenCard(
            dark: dark,
            child: Column(
              children: [
                _AccountRow(
                  icon: Icons.notifications_none_rounded,
                  label: l10n.notificationsTitle,
                  dark: dark,
                  onTap: () {},
                ),
                Divider(height: 1, thickness: 1, color: DeenColors.dividerLine(dark)),
                _AccountRow(
                  icon: Icons.public_rounded,
                  label: l10n.prayerMethodTitle,
                  dark: dark,
                  trailingText: l10n.prayerMethodSubtitle,
                  onTap: () {},
                ),
                Divider(height: 1, thickness: 1, color: DeenColors.dividerLine(dark)),
                _AccountRow(
                  icon: Icons.logout_rounded,
                  label: l10n.logoutButton,
                  dark: dark,
                  color: DeenColors.rust,
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: DeenColors.textMuted(dark),
      ),
    );
  }
}

/// One segment of the appearance picker — matches [_LengthChip]-style
/// "pill button" interaction rather than [InkWell], since a ripple on a
/// small rounded segment tends to bleed past the corners.
class _AppearanceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? DeenColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : DeenColors.textMuted(dark)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : DeenColors.textMuted(dark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13.5, color: DeenColors.primaryText(dark)),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 16, color: DeenColors.primary),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dark;
  final Color? color;
  final String? trailingText;
  final VoidCallback onTap;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.dark,
    this.color,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color ?? DeenColors.textMuted(dark)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(fontSize: 13.5, color: color ?? DeenColors.primaryText(dark)),
                ),
              ],
            ),
            if (trailingText != null)
              Text(trailingText!, style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark)))
            else if (color == null)
              Icon(Icons.chevron_right_rounded, size: 18, color: DeenColors.textMuted(dark)),
          ],
        ),
      ),
    );
  }
}
