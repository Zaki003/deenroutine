import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/prayer_provider.dart';
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

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    context.read<HabitProvider>().listenToHabits(uid);
    context.read<PrayerProvider>().loadPrayerTimes();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      (
        icon: Icons.home_rounded,
        label: l10n.navHome,
        screen: DashboardScreen(onSeeAllHabits: () => setState(() => _index = 1)),
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
          onTap: (i) => setState(() => _index = i),
          items: [
            for (final t in tabs)
              BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
          ],
        ),
      ),
    );
  }
}
