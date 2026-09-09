import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/prayer_service.dart';
import '../../theme/deen_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../habits/habits_screen.dart';
import '../prayer/prayer_screen.dart';
import '../profile/profile_screen.dart';
import '../quiz/quiz_home_screen.dart';

/// Bottom-nav shell hosting the 5 top-level tabs (Home, Habits, Prayer,
/// Quiz, Profile). Shared data (habits, prayer times) is loaded once here
/// rather than per-tab, since several tabs read the same providers.
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

// Stable, locale-independent names for screen-view analytics — l10n labels
// would otherwise report a different value per language for the same tab.
const _screenNames = ['Dashboard', 'Habits', 'Prayer', 'Quiz', 'Profile'];

class _MainNavScreenState extends State<MainNavScreen> with WidgetsBindingObserver {
  int _index = 0;
  final _analytics = AnalyticsService();
  // Captured in initState rather than read fresh in dispose() - by the time
  // dispose() runs this context may no longer be able to look up ancestor
  // providers.
  late final HabitProvider _habitProvider;
  late final PrayerProvider _prayerProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _habitProvider = context.read<HabitProvider>();
    _prayerProvider = context.read<PrayerProvider>();
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    _habitProvider.listenToHabits(uid);
    _analytics.logScreenView(_screenNames[_index]);
    // loadPrayerTimes() notifies synchronously before its first await (to
    // flip on isLoading immediately for pull-to-refresh callers), which
    // would hit "setState() called during build" if invoked directly from
    // initState. Defer to after the first frame instead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prayerProvider.loadPrayerTimes();
    });
  }

  void _onTabTap(int i) {
    setState(() => _index = i);
    _analytics.logScreenView(_screenNames[i]);
  }

  /// Location permission is granted/changed in system Settings, entirely
  /// outside the app - the only signal that something might have changed is
  /// the app coming back to the foreground. Without this, a user who denies
  /// location, later flips it on in Settings, and returns to the app stays
  /// stuck on the permission-denied error until they happen to hit Retry
  /// (and on some Android versions/OEM builds, checkPermission() right after
  /// returning from Settings can still report the pre-change status for a
  /// moment - retrying on resume rather than only on that one manual tap
  /// covers that too). Scoped to permission/location-service errors
  /// specifically, not fetchFailed/unknown, so a real network outage doesn't
  /// get hammered with a retry every time the user switches back to the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    const recoverableOnResume = {
      PrayerErrorType.permissionDenied,
      PrayerErrorType.permissionDeniedForever,
      PrayerErrorType.locationServicesDisabled,
    };
    if (_prayerProvider.hasError &&
        recoverableOnResume.contains(_prayerProvider.errorType)) {
      _prayerProvider.loadPrayerTimes();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // _AuthGate unmounts this screen on logout - without this, the habit
    // listener started in initState keeps trying to reconnect as a user
    // who's no longer signed in, forever. See HabitProvider.stopListening.
    _habitProvider.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      (
        icon: Icons.home_rounded,
        label: l10n.navHome,
        screen: DashboardScreen(onSeeAllHabits: () => _onTabTap(1)),
      ),
      (icon: Icons.checklist_rounded, label: l10n.navHabits, screen: const HabitsScreen()),
      (icon: Icons.access_time_rounded, label: l10n.navPrayer, screen: const PrayerScreen()),
      (icon: Icons.menu_book_rounded, label: l10n.navQuiz, screen: const QuizHomeScreen()),
      (icon: Icons.person_outline_rounded, label: l10n.navProfile, screen: const ProfileScreen()),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [for (final t in tabs) t.screen],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: DeenColors.dividerLine(dark))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: _onTabTap,
          items: [
            for (final t in tabs)
              BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
          ],
        ),
      ),
    );
  }
}
