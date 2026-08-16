import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/text_format.dart';

/// FR-03: Profile management, and Settings collection (theme, prayer method).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final user = auth.appUser;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileAppBarTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
              style: TextStyle(fontSize: 32, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),
          Text(capitalizeWords(user?.name ?? ''), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(user?.email ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: Text(l10n.darkModeTitle),
            subtitle: Text(
              themeProvider.themeMode == ThemeMode.system
                  ? l10n.darkModeFollowingSystem
                  : (themeProvider.isDarkMode ? l10n.onLabel : l10n.offLabel),
            ),
            value: themeProvider.isDarkMode,
            onChanged: (enabled) => themeProvider.toggleDarkMode(enabled),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: Text(l10n.useSystemTheme),
            trailing: themeProvider.themeMode == ThemeMode.system
                ? Icon(Icons.check, color: scheme.success)
                : null,
            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
          ),
          ExpansionTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.languageTitle),
            subtitle: Text(
              localeProvider.isBangla ? l10n.languageBangla : l10n.languageEnglish,
            ),
            childrenPadding: EdgeInsets.zero,
            children: [
              ListTile(
                leading: const SizedBox(width: 24),
                title: Text(l10n.languageEnglish),
                trailing: !localeProvider.isBangla
                    ? Icon(Icons.check, color: scheme.success)
                    : null,
                onTap: () => localeProvider.setLocale(const Locale('en')),
              ),
              ListTile(
                leading: const SizedBox(width: 24),
                title: Text(l10n.languageBangla),
                trailing: localeProvider.isBangla
                    ? Icon(Icons.check, color: scheme.success)
                    : null,
                onTap: () => localeProvider.setLocale(const Locale('bn')),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: Text(l10n.prayerMethodTitle),
            subtitle: Text(l10n.prayerMethodSubtitle),
            onTap: () {},
          ),
          const Divider(height: 32),
          FilledButton.tonal(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
    );
  }
}
