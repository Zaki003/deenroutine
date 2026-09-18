import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/habit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/date_format.dart';
import '../../utils/text_format.dart';
import '../../widgets/account_row.dart';
import '../../widgets/avatar_graphic.dart';
import '../../widgets/avatar_picker_dialog.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/edit_name_dialog.dart';
import '../../widgets/section_label.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

/// FR-03: Profile — identity, favorites, and a this-week habit overview.
/// Settings (theme, language, prayer method, account actions) live one tap
/// away via the gear icon, in [SettingsScreen].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final habits = context.watch<HabitProvider>().habits;
    final habitProvider = context.read<HabitProvider>();
    final user = auth.appUser;
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = capitalizeWords(user?.name ?? '');
    // A one-off to-do has no week of recurrence to summarize - excluded the
    // same way the Habits tab and Dashboard already exclude it from
    // streak/week displays.
    final recurringHabits =
        habits.where((h) => h.frequency != HabitFrequency.once).toList();

    return ColoredBox(
      color: DeenColors.surface(dark),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.navProfile,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DeenColors.primaryText(dark),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                color: DeenColors.primaryText(dark),
                tooltip: l10n.settingsTitle,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(23),
                onTap: () => showDialog(context: context, builder: (_) => const AvatarPickerDialog()),
                child: AvatarGraphic(
                  avatar: user?.avatar,
                  initial: (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => EditNameDialog(currentName: name),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: DeenColors.primaryText(dark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined, size: 14, color: DeenColors.textMuted(dark)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DeenCard(
            dark: dark,
            margin: const EdgeInsets.only(bottom: 20),
            child: AccountRow(
              icon: Icons.favorite_border_rounded,
              label: l10n.favoritesTitle,
              dark: dark,
              trailingText: l10n.favoritesCountLabel(
                auth.appUser?.favoriteQuoteIds.length ?? 0,
                AuthProvider.maxFreeFavorites,
              ),
              showChevron: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
            ),
          ),
          if (recurringHabits.isNotEmpty) ...[
            SectionLabel(l10n.thisWeekLabel),
            const SizedBox(height: 8),
            _WeekStatsCard(
              recurringHabits: recurringHabits,
              totalHabitsCount: habits.length,
              habitProvider: habitProvider,
              dark: dark,
            ),
          ],
        ],
      ),
    );
  }
}

/// This week's ring + bar chart, plus the best-habit/habits-tracked tiles
/// below it. Waits on one [HabitProvider.weekFor] call per habit - the same
/// per-habit `HabitLogs` query the Habits tab's week picker already makes,
/// just aggregated across every recurring habit instead of shown per-row.
class _WeekStatsCard extends StatelessWidget {
  final List<Habit> recurringHabits;
  final int totalHabitsCount;
  final HabitProvider habitProvider;
  final bool dark;

  const _WeekStatsCard({
    required this.recurringHabits,
    required this.totalHabitsCount,
    required this.habitProvider,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<List<bool>>>(
      future: Future.wait(recurringHabits.map(habitProvider.weekFor)),
      builder: (context, snapshot) {
        final weeks = snapshot.data;
        if (weeks == null) {
          return DeenCard(
            dark: dark,
            margin: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 62,
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: dark ? DeenColors.goldSoft : DeenColors.primary,
                  ),
                ),
              ),
            ),
          );
        }

        final dayCounts = List.generate(7, (i) => weeks.where((w) => w[i]).length);
        final totalDone = dayCounts.fold(0, (sum, c) => sum + c);
        final totalPossible = recurringHabits.length * 7;

        var bestIndex = -1;
        var bestCount = 0;
        for (var i = 0; i < recurringHabits.length; i++) {
          final count = weeks[i].where((done) => done).length;
          if (count > bestCount) {
            bestCount = count;
            bestIndex = i;
          }
        }

        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        // DateTime.weekday is 1=Mon..7=Sun, matching FirestoreService.weekCompletion.
        final monday = todayMidnight.subtract(Duration(days: todayMidnight.weekday - 1));

        return Column(
          children: [
            DeenCard(
              dark: dark,
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _WeekRing(done: totalDone, total: totalPossible, dark: dark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _WeekBars(
                      dayCounts: dayCounts,
                      dark: dark,
                      dayLabels: [
                        for (var i = 0; i < 7; i++)
                          '${formatShortDate(l10n.localeName, monday.add(Duration(days: i)))}, '
                          '${dayCounts[i] == 0 ? l10n.noHabitsCompletedOnDay : l10n.habitsCompletedOnDay(dayCounts[i])}',
                      ],
                      onTapDay: (dayIndex) {
                        final day = monday.add(Duration(days: dayIndex));
                        final titles = [
                          for (var i = 0; i < recurringHabits.length; i++)
                            if (weeks[i][dayIndex]) recurringHabits[i].title,
                        ];
                        _showDayDetail(context, l10n, dark, day, titles);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: bestIndex >= 0
                      ? _BestHabitTile(
                          habitTitle: recurringHabits[bestIndex].title,
                          daysThisWeek: bestCount,
                          dark: dark,
                        )
                      : _StatTile(label: l10n.bestHabitLabel, value: '—', dark: dark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: l10n.habitsTrackedLabel,
                    value: '$totalHabitsCount',
                    dark: dark,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Animated done/total ring for the week, styled like the Dashboard's daily
/// [BarakahCircle] (same gold-on-track palette) but a plain
/// [CircularProgressIndicator] rather than that widget's own painter/label,
/// since "TODAY" is baked into [BarakahCircle] and isn't true here.
class _WeekRing extends StatelessWidget {
  final int done;
  final int total;
  final bool dark;

  const _WeekRing({required this.done, required this.total, required this.dark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final target = total == 0 ? 0.0 : done / total;
    return Semantics(
      label: l10n.weekProgressLabel(done, total),
      excludeSemantics: true,
      child: SizedBox(
        width: 62,
        height: 62,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor:
                    dark ? Colors.white.withValues(alpha: 0.10) : DeenColors.primary.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(DeenColors.gold),
              ),
              Text(
                '$done/$total',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeenColors.primaryText(dark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mon-Sun bar chart, each bar's height relative to the week's own busiest
/// day so the chart stays readable regardless of how many habits exist.
/// Tapping a day hands it off to [onTapDay] rather than tracking selection
/// itself - the caller opens a bottom sheet, so there's no persistent
/// "selected day" state to hold here.
class _WeekBars extends StatelessWidget {
  static const _maxBarHeight = 40.0;

  final List<int> dayCounts;
  final List<String> dayLabels;
  final bool dark;
  final ValueChanged<int> onTapDay;

  const _WeekBars({
    required this.dayCounts,
    required this.dayLabels,
    required this.dark,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = dayCounts.fold(0, (m, c) => c > m ? c : m);
    return SizedBox(
      height: _maxBarHeight,
      // A bar's width is a share of its own slot rather than a fixed pixel
      // value, so the chart fills the available width on a wider screen
      // (tablet, landscape) instead of leaving 7 skinny bars stranded in
      // wide gaps - clamped so it still reads as a bar, not a block.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = (constraints.maxWidth / 7 * 0.5).clamp(6.0, 18.0);
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Semantics(
                      label: dayLabels[i],
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => onTapDay(i),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: barWidth,
                            height: (maxCount == 0 ? 0.0 : _maxBarHeight * (dayCounts[i] / maxCount) * t)
                                .clamp(3.0, _maxBarHeight),
                            decoration: BoxDecoration(
                              color: dayCounts[i] == 0
                                  ? DeenColors.outlineFaint(dark)
                                  : (dark ? DeenColors.goldSoft : DeenColors.primary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _showDayDetail(
  BuildContext context,
  AppLocalizations l10n,
  bool dark,
  DateTime day,
  List<String> completedTitles,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: DeenColors.cardBackground(dark),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 34,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: DeenColors.outlineFaint(dark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              formatShortDate(l10n.localeName, day),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DeenColors.primaryText(dark)),
            ),
            const SizedBox(height: 2),
            Text(
              completedTitles.isEmpty
                  ? l10n.noHabitsCompletedOnDay
                  : l10n.habitsCompletedOnDay(completedTitles.length),
              style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark)),
            ),
            const SizedBox(height: 12),
            for (final title in completedTitles)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, size: 16, color: dark ? DeenColors.goldSoft : DeenColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: DeenColors.primaryText(dark)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The habit with the most completed days this week - tap to reveal which
/// one it is. Collapsed by default so a fresh Profile screen reads as a
/// plain stat tile, matching [_StatTile] beside it.
class _BestHabitTile extends StatefulWidget {
  final String habitTitle;
  final int daysThisWeek;
  final bool dark;

  const _BestHabitTile({required this.habitTitle, required this.daysThisWeek, required this.dark});

  @override
  State<_BestHabitTile> createState() => _BestHabitTileState();
}

class _BestHabitTileState extends State<_BestHabitTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      expanded: _expanded,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: DeenCard(
          dark: widget.dark,
          padding: const EdgeInsets.all(10),
          child: Column(
            // .stretch (rather than .start, like the plain _StatTile beside
            // this) keeps the AnimatedSize child's width identical between
            // its collapsed and expanded states, so only the height animates.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.bestHabitLabel,
                    style: TextStyle(fontSize: 10, color: DeenColors.textMuted(widget.dark)),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: DeenColors.textMuted(widget.dark)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.habitTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: DeenColors.primaryText(widget.dark)),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          l10n.bestHabitDaysSubtitle(widget.daysThisWeek),
                          style: TextStyle(fontSize: 10, color: DeenColors.textMuted(widget.dark)),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;

  const _StatTile({required this.label, required this.value, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: DeenCard(
        dark: dark,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: DeenColors.textMuted(dark))),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DeenColors.primaryText(dark)),
            ),
          ],
        ),
      ),
    );
  }
}
