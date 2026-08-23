import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/daily_quote.dart';
import '../../models/habit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/deen_colors.dart';
import '../../utils/duration_format.dart';
import '../../utils/habit_error_messages.dart';
import '../../utils/prayer_labels.dart';
import '../../utils/text_format.dart';
import '../../widgets/barakah_circle.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/gradient_hero_card.dart';
import '../../widgets/habit_actions_menu.dart';
import '../../widgets/habit_checkbox.dart';
import '../../widgets/habit_template_sheet.dart';
import '../../widgets/star_pattern.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/update_location_action.dart';

/// FR-06: Dashboard displaying the greeting, a daily Ayah/Hadith, the
/// next-prayer countdown, the Barakah Circle, and today's habits.
class DashboardScreen extends StatefulWidget {
  /// Switches the bottom nav to the Habits tab. Used by the "see all"
  /// link once the today list is capped (see [_maxVisibleHabits]).
  final VoidCallback onSeeAllHabits;

  const DashboardScreen({super.key, required this.onSeeAllHabits});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Above this many habits, the dashboard shows only the top ones (incomplete
/// first) plus a link to the full list, instead of growing into a second
/// copy of the Habits tab as someone adds more habits.
const _maxVisibleHabits = 5;

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestoreService = FirestoreService();
  DailyQuote? _quote;

  @override
  void initState() {
    super.initState();
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = capitalizeWords(context.watch<AuthProvider>().appUser?.name ?? '');

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

    // Only habits actually scheduled for today — daily/weekly habits always
    // qualify, a specificDays habit only when today is one of its
    // selectedDays. The Habits tab is still the place to see every habit
    // regardless of day.
    final todaysHabits = habitProvider.habits.where((h) => h.isDueToday).toList();
    final done = todaysHabits.where((h) => h.isCompletedToday).length;
    final total = todaysHabits.length;

    // Incomplete habits float to the top — those are the ones that still
    // need action today — and the list is capped so the dashboard stays a
    // glanceable summary instead of growing into a duplicate of the Habits
    // tab as someone adds more habits.
    final orderedHabits = [
      ...todaysHabits.where((h) => !h.isCompletedToday),
      ...todaysHabits.where((h) => h.isCompletedToday),
    ];
    final visibleHabits = orderedHabits.take(_maxVisibleHabits).toList();
    final hiddenHabitCount = orderedHabits.length - visibleHabits.length;

    return ColoredBox(
      color: DeenColors.surface(dark),
      child: RefreshIndicator(
        onRefresh: () => prayerProvider.loadPrayerTimes(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              l10n.assalamuAlaikumGreeting,
              style: TextStyle(fontSize: 12, color: DeenColors.gold, letterSpacing: 1),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DeenColors.primaryText(dark),
              ),
            ),
            const SizedBox(height: 16),
            if (_quote != null) ...[
              _QuoteCard(quote: _quote!, isBangla: isBangla, dark: dark),
              const SizedBox(height: 16),
            ],
            _PrayerHero(provider: prayerProvider, l10n: l10n),
            const SizedBox(height: 16),
            DeenCard(
              dark: dark,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        StarPattern(opacity: 0.12, color: DeenColors.gold),
                        BarakahCircle(done: done, total: total, dark: dark, size: 100),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.barakahCircleTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DeenColors.primaryText(dark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _summary(l10n, done, total, prayerProvider.nextPrayerName),
                          style: const TextStyle(fontSize: 12, color: DeenColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.todaysHabitsTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DeenColors.primaryText(dark),
                  ),
                ),
                GestureDetector(
                  onTap: () => showHabitTemplateSheet(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: DeenColors.gold,
                    ),
                    child: const Icon(Icons.add, size: 18, color: DeenColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (habitProvider.habits.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.noHabitsYet,
                    style: const TextStyle(color: DeenColors.textMuted)),
              )
            else if (todaysHabits.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.noHabitsToday,
                    style: const TextStyle(color: DeenColors.textMuted)),
              ),
            for (final habit in visibleHabits)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DashboardHabitRow(
                  habit: habit,
                  dark: dark,
                  onToggle: () => habitProvider.toggleComplete(habit),
                ),
              ),
            if (hiddenHabitCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onSeeAllHabits,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.seeAllHabits(habitProvider.habits.length),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: DeenColors.gold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: DeenColors.gold),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _summary(AppLocalizations l10n, int done, int total, String? nextPrayerKey) {
    final remaining = total - done;
    if (total == 0 || remaining <= 0) {
      return l10n.barakahSummaryComplete(total);
    }
    final prayer = nextPrayerKey != null ? prayerNameLabel(l10n, nextPrayerKey) : '';
    return l10n.barakahSummaryRemaining(done, total, remaining, prayer);
  }
}

class _PrayerHero extends StatelessWidget {
  final PrayerProvider provider;
  final AppLocalizations l10n;

  const _PrayerHero({required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const SizedBox(
        height: 64,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (provider.hasError || provider.nextPrayerName == null) {
      return const SizedBox.shrink();
    }
    final remaining = provider.timeUntilNextPrayer;
    return GradientHeroCard(
      compact: true,
      eyebrow: l10n.nextPrayerLabel,
      prayerName: prayerNameLabel(l10n, provider.nextPrayerName!),
      timeLabel: provider.nextPrayerTime ?? '',
      remainingLabel: remaining != null
          ? l10n.prayerRemainingShort(formatCountdown(remaining))
          : '',
      onUpdateLocation: () => confirmUpdateLocation(context),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final DailyQuote quote;
  final bool isBangla;
  final bool dark;

  const _QuoteCard({required this.quote, required this.isBangla, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeenColors.panelBackground(dark),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          StarPattern(opacity: dark ? 0.06 : 0.08, color: DeenColors.gold),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote.displayText(isBangla),
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                  height: 1.5,
                  color: dark ? DeenColors.goldSoft : DeenColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                quote.source,
                style: const TextStyle(fontSize: 11, color: DeenColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardHabitRow extends StatelessWidget {
  final Habit habit;
  final bool dark;
  final VoidCallback onToggle;

  const _DashboardHabitRow({
    required this.habit,
    required this.dark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedToday;
    return HabitActionsMenu(
      habit: habit,
      child: DeenCard(
        dark: dark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            HabitCheckbox(done: done, dark: dark, onTap: onToggle),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                habit.title,
                style: TextStyle(
                  fontSize: 13,
                  color: DeenColors.primaryText(dark),
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: DeenColors.primaryText(dark).withValues(alpha: 0.6),
                ),
              ),
            ),
            FutureBuilder<int>(
              future: context.read<HabitProvider>().streakFor(habit),
              builder: (context, snapshot) => StreakBadge(streak: snapshot.data ?? 0, dark: dark),
            ),
          ],
        ),
      ),
    );
  }
}
