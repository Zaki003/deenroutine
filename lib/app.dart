import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/analytics_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_nav_screen.dart';
import 'utils/app_theme.dart';

class DeenRoutineApp extends StatelessWidget {
  const DeenRoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: 'DeenRoutine',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final Widget child;
        if (!auth.authResolved) {
          // Firebase hasn't confirmed whether a session is persisted yet -
          // showing this instead of LoginScreen avoids a flash of the login
          // form for already-logged-in users a split second before
          // MainNavScreen takes over.
          child = const _LaunchSplash(key: ValueKey('splash'));
        } else if (auth.isLoggedIn && !auth.inOnboarding) {
          child = const MainNavScreen(key: ValueKey('main'));
        } else {
          child = const LoginScreen(key: ValueKey('login'));
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: child,
        );
      },
    );
  }
}

/// Neutral placeholder shown only until [AuthProvider.authResolved] flips —
/// mirrors LoginScreen's own branding block (same icon, same title, same
/// position) so that if the app lands on LoginScreen next, nothing visibly
/// changes; if it lands on MainNavScreen instead, the crossfade in
/// [_AuthGate] eases into it rather than popping.
class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mosque, size: 64, color: Theme.of(context).colorScheme.success),
            const SizedBox(height: 12),
            Text(
              l10n.appTitle,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}