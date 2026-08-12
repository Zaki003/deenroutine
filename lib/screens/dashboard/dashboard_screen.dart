import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/daily_quote.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/habit_error_messages.dart';
import '../../utils/prayer_error_messages.dart';
import '../../utils/prayer_labels.dart';
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
    final isBangla = context.watch<LocaleProvider>().isBangla;
    final l10n = AppLocalizations.of(context)!;

    if (habitProvider.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(habitErrorMessage(
                l10n, habitProvider.errorType!, habitProvider.errorDetail)),
          ),
        );
        habitProvider.clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
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
            Text(
              l10n.barakahCircleTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
                l10n.habitsDoneToday(
                  habitProvider.habits.where((h) => h.isCompletedToday).length,
                  habitProvider.habits.length,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildPrayerTimesCard(prayerProvider, l10n),
            if (_quote != null) _buildQuoteCard(_quote!, isBangla),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(l10n.todaysHabitsTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (habitProvider.habits.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noHabitsYet),
              ),
            for (final habit in habitProvider.habits)
              HabitCard(
                habit: habit,
                onToggle: () => habitProvider.toggleComplete(habit),
                onDelete: () => habitProvider.deleteHabit(habit.habitId),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddHabitScreen(editingHabit: habit),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesCard(PrayerProvider provider, AppLocalizations l10n) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l10n.prayerTimesUnavailable(
              prayerErrorMessage(l10n, provider.errorType!, provider.errorDetail)),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    final ordered = provider.orderedTimings;
    if (ordered.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final nextPrayer = provider.nextPrayerName;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: ordered.map((e) {
            final isNext = e.key == nextPrayer;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isNext ? scheme.successContainer : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    prayerNameLabel(l10n, e.key),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isNext ? scheme.onSuccessContainer : null,
                    ),
                  ),
                  Text(
                    e.value,
                    style: TextStyle(
                      color: isNext ? scheme.onSuccessContainer : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(DailyQuote quote, bool isBangla) {
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
              quote.displayText(isBangla),
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
