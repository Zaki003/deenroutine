import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/daily_quote.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/barakah_circle.dart';
import '../../widgets/habit_card.dart';
import '../habits/add_habit_screen.dart';
import '../quiz/quiz_setup_dialog.dart';
import '../profile/profile_screen.dart';

/// FR-06: Dashboard displaying daily habits, completion %, streaks,
/// Barakah Circle, prayer times, and a daily Ayah/Hadith.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestoreService = FirestoreService();
  DailyQuote? _quote;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    context.read<HabitProvider>().listenToHabits(uid);
    context.read<PrayerProvider>().loadPrayerTimes();
    _firestoreService.getDailyQuote().then((q) {
      if (mounted) setState(() => _quote = q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final prayerProvider = context.watch<PrayerProvider>();

    if (habitProvider.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(habitProvider.error!)),
        );
        habitProvider.clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DeenRoutine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            onPressed: () => startQuiz(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddHabitScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => prayerProvider.loadPrayerTimes(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 16),
            const Text(
              'Barakah Circle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: BarakahCircle(percentage: habitProvider.completionPercentage),
            ),
            if (habitProvider.habits.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${habitProvider.habits.where((h) => h.isCompletedToday).length} of '
                '${habitProvider.habits.length} habits done today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildPrayerTimesCard(prayerProvider),
            if (_quote != null) _buildQuoteCard(_quote!),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Today\'s Habits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (habitProvider.habits.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No habits yet. Tap + to add your first one.'),
              ),
            for (final habit in habitProvider.habits)
              HabitCard(
                habit: habit,
                onToggle: () => habitProvider.toggleComplete(habit),
                onDelete: () => habitProvider.deleteHabit(habit.habitId),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesCard(PrayerProvider provider) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Prayer times unavailable: ${provider.error}',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }
    final t = provider.timings;
    if (t.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: t.entries
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(e.value),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(DailyQuote quote) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: scheme.successContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.text,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: scheme.onSuccessContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '— ${quote.source}',
              style: TextStyle(
                fontSize: 12,
                // Same ink as the quote, stepped back so the citation reads as
                // secondary without dropping out of contrast on either surface.
                color: scheme.onSuccessContainer.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}