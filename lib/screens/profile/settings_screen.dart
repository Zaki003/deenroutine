import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/share_prompt_service.dart';
import '../../theme/deen_colors.dart';
import '../../utils/prayer_method_labels.dart';
import '../../widgets/account_row.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/delete_account_dialog.dart';
import '../../widgets/prayer_method_action.dart';
import '../../widgets/section_label.dart';
import '../../widgets/update_location_action.dart';

const _privacyPolicyUrl = 'https://zaki003.github.io/deenroutine/privacy-policy.html';

Future<void> _openPrivacyPolicy(BuildContext context) async {
  final opened =
      await launchUrl(Uri.parse(_privacyPolicyUrl), mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.linkOpenFailed)),
    );
  }
}

/// FR-03: Settings collection (theme, language, prayer method, account
/// actions) — everything the profile screen isn't itself: identity,
/// favorites and this-week stats stay there, reached from here via the
/// gear icon.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final prayerProvider = context.watch<PrayerProvider>();
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ColoredBox(
        color: DeenColors.surface(dark),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            SectionLabel(l10n.profilePreferencesLabel),
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
            DeenCard(
              dark: dark,
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.usageAnalyticsTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DeenColors.primaryText(dark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.usageAnalyticsBody,
                          style: TextStyle(
                              fontSize: 11.5, height: 1.4, color: DeenColors.textMuted(dark)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: analyticsProvider.enabled,
                    onChanged: (value) => analyticsProvider.setEnabled(value),
                    activeThumbColor: DeenColors.primary,
                  ),
                ],
              ),
            ),
            SectionLabel(l10n.profileAccountLabel),
            const SizedBox(height: 8),
            DeenCard(
              dark: dark,
              child: Column(
                children: [
                  AccountRow(
                    icon: Icons.notifications_none_rounded,
                    label: l10n.notificationsTitle,
                    dark: dark,
                    onTap: () {},
                  ),
                  Divider(height: 1, thickness: 1, color: DeenColors.dividerLine(dark)),
                  AccountRow(
                    icon: Icons.public_rounded,
                    label: l10n.prayerMethodTitle,
                    dark: dark,
                    trailingText: '${prayerMethodLabel(l10n, prayerProvider.calculationMethod)} · '
                        '${asrMethodLabel(l10n, prayerProvider.asrMethod)}',
                    showChevron: true,
                    onTap: () => confirmPrayerMethod(context),
                  ),
                  Divider(height: 1, thickness: 1, color: DeenColors.dividerLine(dark)),
                  AccountRow(
                    icon: Icons.location_on_rounded,
                    label: l10n.profileLocationLabel,
                    dark: dark,
                    trailingText: prayerProvider.isManualLocation
                        ? l10n.currentLocationCity(prayerProvider.manualCityLabel!)
                        : l10n.currentLocationGps,
                    showChevron: true,
                    onTap: () => confirmUpdateLocation(context),
                  ),
                  Divider(height: 1, thickness: 1, color: DeenColors.dividerLine(dark)),
                  AccountRow(
                    icon: Icons.logout_rounded,
                    label: l10n.logoutButton,
                    dark: dark,
                    color: dark ? DeenColors.rustLight : DeenColors.rust,
                    onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                  Divider(height: 1, thickness: 1, color: DeenColors.dividerLine(dark)),
                  AccountRow(
                    icon: Icons.delete_outline_rounded,
                    label: l10n.deleteAccountButton,
                    dark: dark,
                    color: dark ? DeenColors.rustLight : DeenColors.rust,
                    onTap: () async {
                      final deleted = await showDialog<bool>(
                        context: context,
                        builder: (_) => const DeleteAccountDialog(),
                      );
                      if (deleted == true && context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionLabel(l10n.profileAboutLabel),
            const SizedBox(height: 8),
            DeenCard(
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noAdsTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DeenColors.primaryText(dark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.noAdsBody,
                    style: TextStyle(fontSize: 12, height: 1.4, color: DeenColors.textMuted(dark)),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, thickness: 1, color: DeenColors.dividerLine(dark)),
                  AccountRow(
                    icon: Icons.ios_share_rounded,
                    label: l10n.shareInviteTitle,
                    dark: dark,
                    onTap: () {
                      AnalyticsService().logShareTapped(source: 'settings');
                      SharePromptService().share();
                    },
                  ),
                  Divider(height: 1, thickness: 1, color: DeenColors.dividerLine(dark)),
                  AccountRow(
                    icon: Icons.privacy_tip_outlined,
                    label: l10n.privacyPolicyLabel,
                    dark: dark,
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                ],
              ),
            ),
          ],
        ),
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
