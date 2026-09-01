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
import '../../utils/app_theme.dart';
import '../../utils/duration_format.dart';
import '../../utils/habit_error_messages.dart';
import '../../utils/habit_progress_subtitle.dart';
import '../../utils/prayer_error_messages.dart';
import '../../utils/prayer_labels.dart';
import '../../utils/text_format.dart';
import '../../widgets/barakah_circle.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/gradient_hero_card.dart';
import '../../widgets/habit_actions_menu.dart';
import '../../widgets/habit_checkbox.dart';
import '../../widgets/habit_progress_ring.dart';
import '../../widgets/habit_template_sheet.dart';
import '../../widgets/habit_timer_control.dart';
import '../../widgets/milestone_banner.dart';
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
            backgroundColor: DeenColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: DeenColors.goldSoft),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habitErrorMessage(l10n, habitProvider.errorType!, habitProvider.errorDetail),
                    style: const TextStyle(color: DeenColors.paper, fontSize: 13),
                  ),
                ),
              ],
            ),
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
    final milestone = habitProvider.pendingMilestone;

    return Stack(
      children: [
        _dashboardBody(l10n, habitProvider, prayerProvider, dark, isBangla, name, done, total,
            todaysHabits, visibleHabits, hiddenHabitCount),
        if (milestone != null)
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: MilestoneBanner(
              key: ValueKey('${milestone.habitId}_${milestone.days}'),
              event: milestone,
              onDismissed: () => context.read<HabitProvider>().consumeMilestone(),
            ),
          ),
      ],
    );
  }

  Widget _dashboardBody(
    AppLocalizations l10n,
    HabitProvider habitProvider,
    PrayerProvider prayerProvider,
    bool dark,
    bool isBangla,
    String name,
    int done,
    int total,
    List<Habit> todaysHabits,
    List<Habit> visibleHabits,
    int hiddenHabitCount,
  ) {
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
                          style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark)),
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
              EmptyStateCard(icon: Icons.checklist_rounded, message: l10n.noHabitsYet, dark: dark)
            else if (todaysHabits.isEmpty)
              EmptyStateCard(
                  icon: Icons.event_available_outlined, message: l10n.noHabitsToday, dark: dark),
            for (final habit in visibleHabits)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DashboardHabitRow(habit: habit, dark: dark),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (provider.isLoading) {
      return SizedBox(
        height: 64,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: DeenColors.gold),
        ),
      );
    }
    if (provider.hasError) {
      return EmptyStateCard(
        icon: Icons.cloud_off_rounded,
        iconColor: DeenColors.rust,
        title: l10n.prayerUnavailableTitle,
        message: prayerErrorMessage(l10n, provider.errorType!, provider.errorDetail),
        dark: dark,
        compact: true,
        actionLabel: l10n.retryButton,
        onAction: () => provider.loadPrayerTimes(),
      );
    }
    if (provider.nextPrayerName == null) {
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
                style: TextStyle(fontSize: 11, color: DeenColors.textMuted(dark)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardHabitRow extends StatefulWidget {
  final Habit habit;
  final bool dark;

  const _DashboardHabitRow({required this.habit, required this.dark});

  @override
  State<_DashboardHabitRow> createState() => _DashboardHabitRowState();
}

class _DashboardHabitRowState extends State<_DashboardHabitRow> {
  /// Checklist item list, or rating star picker — whichever the habit's
  /// tracking type uses. Purely local UI state, never persisted; collapses
  /// again on its own tap, not automatically on completion.
  bool _expanded = false;

  /// Avoidance only: whether the "log a slip?" confirm bar is open. Kept
  /// separate from [_expanded] since it's a confirm gate, not a picker.
  bool _confirmingSlip = false;

  Habit get habit => widget.habit;
  bool get dark => widget.dark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final done = habit.isCompletedToday;
    final subtitle = habitProgressSubtitle(l10n, habit);
    final showRatingPicker = habit.trackingType == HabitTrackingType.rating && _expanded;
    final isAvoidance = habit.trackingType == HabitTrackingType.avoidance;

    return HabitActionsMenu(
      habit: habit,
      child: DeenCard(
        dark: dark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _leadingControl(context, done),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: DeenColors.primaryText(dark),
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: DeenColors.primaryText(dark).withValues(alpha: 0.6),
                        ),
                      ),
                      if (showRatingPicker)
                        _ratingStarsRow(context)
                      else if (isAvoidance)
                        _avoidanceStatusLine(context)
                      else if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 11, color: DeenColors.textMuted(dark)),
                        ),
                      ],
                    ],
                  ),
                ),
                FutureBuilder<int>(
                  future: context.read<HabitProvider>().streakFor(habit),
                  builder: (context, snapshot) => StreakBadge(streak: snapshot.data ?? 0, dark: dark),
                ),
              ],
            ),
            if (habit.trackingType == HabitTrackingType.checklist && _expanded)
              _checklistItemsSection(context),
            if (isAvoidance && _confirmingSlip) _avoidanceConfirmSection(context),
          ],
        ),
      ),
    );
  }

  Widget _leadingControl(BuildContext context, bool done) {
    switch (habit.trackingType) {
      case HabitTrackingType.numeric:
        final current = habit.hasProgressToday ? habit.todayProgressValue : 0;
        return HabitProgressRing(
          progress: habit.numericTarget == 0 ? 0 : current / habit.numericTarget,
          done: done,
          dark: dark,
          onTap: done
              ? () => context.read<HabitProvider>().undoCompletion(habit)
              : () => context.read<HabitProvider>().logNumericProgress(habit),
          centerGlyph: Text(
            '$current',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: DeenColors.primaryText(dark),
            ),
          ),
        );
      case HabitTrackingType.timer:
        return HabitTimerControl(habit: habit, dark: dark);
      case HabitTrackingType.checklist:
        final total = habit.checklistItems.length;
        final doneItems = habit.hasProgressToday ? habit.todayChecklistDone : const <String>[];
        final doneCount = doneItems.where(habit.checklistItems.contains).length;
        return HabitProgressRing(
          progress: total == 0 ? 0 : doneCount / total,
          done: done,
          dark: dark,
          onTap: () => setState(() => _expanded = !_expanded),
          centerGlyph: Text(
            '$doneCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: DeenColors.primaryText(dark),
            ),
          ),
        );
      case HabitTrackingType.rating:
        // No arc — rating is unrated/rated, never partial — so the ring
        // just shows an empty track until it converges on the same solid
        // tick every other type uses once rated.
        return HabitProgressRing(
          progress: 0,
          done: done,
          dark: dark,
          onTap: done
              ? () => context.read<HabitProvider>().undoCompletion(habit)
              : () => setState(() => _expanded = !_expanded),
          centerGlyph: Icon(Icons.star_outline, size: 15, color: DeenColors.textMuted(dark)),
        );
      case HabitTrackingType.yesNo:
        return HabitCheckbox(
          done: done,
          dark: dark,
          onTap: () => context.read<HabitProvider>().toggleComplete(habit),
        );
      case HabitTrackingType.avoidance:
        // Deliberately not a tap target: avoidance's only write is a slip
        // (see logAvoidanceSlip), so a naive toggle here would create a
        // HabitLogs doc on a plain tap and silently break the streak — the
        // flag is a status indicator only, the ghost-link below is the one
        // real trigger.
        final slipLoggedToday = habit.hasProgressToday;
        return SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            slipLoggedToday ? Icons.flag : Icons.flag_outlined,
            size: 20,
            color: slipLoggedToday ? DeenColors.rust : DeenColors.textMuted(dark),
          ),
        );
    }
  }

  Widget _avoidanceStatusLine(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (habit.hasProgressToday) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          l10n.avoidanceSlipLoggedToday,
          style: const TextStyle(fontSize: 11, color: DeenColors.rust),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: InkWell(
        onTap: () => setState(() => _confirmingSlip = true),
        child: Text(
          l10n.avoidanceLogSlipLink,
          style: TextStyle(
            fontSize: 11,
            color: DeenColors.textMuted(dark),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _avoidanceConfirmSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.avoidanceConfirmTitle,
              style: TextStyle(fontSize: 11.5, color: DeenColors.primaryText(dark)),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _confirmingSlip = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                l10n.cancelButton,
                style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark)),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<HabitProvider>().logAvoidanceSlip(habit);
              setState(() => _confirmingSlip = false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DeenColors.rust,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.avoidanceConfirmButton,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistItemsSection(BuildContext context) {
    final doneItems =
        (habit.hasProgressToday ? habit.todayChecklistDone : const <String>[]).toSet();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in habit.checklistItems)
            InkWell(
              onTap: () {
                final updated = Set<String>.from(doneItems);
                if (updated.contains(item)) {
                  updated.remove(item);
                } else {
                  updated.add(item);
                }
                context.read<HabitProvider>().logChecklistProgress(
                      habit,
                      habit.checklistItems.where(updated.contains).toList(),
                    );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 48, top: 5, bottom: 5),
                child: Row(
                  children: [
                    _ChecklistDot(done: doneItems.contains(item), dark: dark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          color: doneItems.contains(item)
                              ? DeenColors.textMuted(dark)
                              : DeenColors.primaryText(dark),
                          decoration: doneItems.contains(item) ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ratingStarsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var value = 1; value <= habit.ratingScale; value++)
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                context.read<HabitProvider>().logRating(habit, value);
                setState(() => _expanded = false);
              },
              child: Icon(Icons.star_outline, size: 18, color: DeenColors.gold),
            ),
        ],
      ),
    );
  }
}

/// Small filled/outline circle used for an individual checklist item — the
/// same idea as [HabitCheckbox] at a much smaller size, no animation.
class _ChecklistDot extends StatelessWidget {
  final bool done;
  final bool dark;

  const _ChecklistDot({required this.done, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? DeenColors.primary : Colors.transparent,
        border: Border.all(color: done ? DeenColors.primary : DeenColors.outlineFaint(dark)),
      ),
      child: done ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
    );
  }
}
