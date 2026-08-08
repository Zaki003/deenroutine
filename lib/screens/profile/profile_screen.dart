import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_theme.dart';

/// FR-03: Profile management, and Settings collection (theme, prayer method).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.appUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
          Text(user?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(user?.email ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: const Text('Dark mode'),
            subtitle: Text(
              themeProvider.themeMode == ThemeMode.system
                  ? 'Following system setting'
                  : (themeProvider.isDarkMode ? 'On' : 'Off'),
            ),
            value: themeProvider.isDarkMode,
            onChanged: (enabled) => themeProvider.toggleDarkMode(enabled),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: const Text('Use system theme'),
            trailing: themeProvider.themeMode == ThemeMode.system
                ? Icon(Icons.check, color: scheme.success)
                : null,
            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Prayer calculation method'),
            subtitle: const Text('MWL (default)'),
            onTap: () {},
          ),
          const Divider(height: 32),
          FilledButton.tonal(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}