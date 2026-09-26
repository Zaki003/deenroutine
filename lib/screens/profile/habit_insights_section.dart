import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/habit_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/date_format.dart';
import '../../utils/habit_error_messages.dart';
import '../../utils/habit_insights.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/stat_tile.dart';

/// The Profile's "Habit insights": three headline numbers, the last four
/// weeks as a calendar grid, this week's bars (tap a day to see what was
/// done), and streak milestones. Open by default, unlike Prayer insights -
/// habit stats aren't sensitive, and they're the Profile's main content -
/// but it collapses the same way, and the choice is remembered per device.
/// Only fetches history while open.
class HabitInsightsSection extends StatefulWidget {
  const HabitInsightsSection({super.key});

  @override
  State<HabitInsightsSection> createState() => _HabitInsightsSectionState();
}

class _HabitInsightsSectionState extends State<HabitInsightsSection> {
  static const _expandedKey = 'profile_habit_insights_expanded';

  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getBool(_expandedKey);
      if (mounted && saved != null && saved != _expanded) setState(() => _expanded = saved);
    });
  }

  Future<void> _toggle() async {
    setState(() => _expanded = !_expanded);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_expandedKey, _expanded);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _toggle,
              child: DeenCard(
                dark: dark,
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded, size: 22, color: dark ? DeenColors.goldSoft : DeenColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.habitInsightsTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DeenColors.primaryText(dark),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.habitInsightsSubtitle,
                            style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark)),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: DeenColors.textMuted(dark)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded ? const _HabitInsightsBody() : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _HabitInsightsBody extends StatelessWidget {
  const _HabitInsightsBody();

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>();
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final insights = habits.insights;

    if (insights == null) {
      final error = habits.insightsErrorType;
      if (error == null) {
        // Fetches only what's missing (a new day, or a habit added since),
        // so this is cheap to ask for on every build that lacks data.
        WidgetsBinding.instance.addPostFrameCallback((_) => habits.loadInsightsHistory());
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
        child: error != null
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      habitErrorMessage(l10n, error, null),
                      style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark)),
                    ),
                  ),
                  TextButton(
                    onPressed: habits.loadInsightsHistory,
                    child: Text(l10n.retryButton, style: TextStyle(color: DeenColors.primaryText(dark))),
                  ),
                ],
              )
            : Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: dark ? DeenColors.goldSoft : DeenColors.primary,
                  ),
                ),
              ),
      );
    }

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final dayCounts = [for (final t in insights.weekDoneTitles) t.length];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: StatTile(label: l10n.habitBestStreakLabel, value: '${insights.bestStreak}', dark: dark)),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  label: l10n.habitRateLabel,
                  value: insights.ratePercent == null ? '—' : '${insights.ratePercent}%',
                  dark: dark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: l10n.habitCheckInsLabel, value: '${insights.checkIns}', dark: dark)),
            ],
          ),
          const SizedBox(height: 10),
          DeenCard(
            dark: dark,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Semantics(
              label: [
                l10n.habitInsightsSubtitle,
                if (insights.ratePercent != null) '${l10n.habitRateLabel}: ${insights.ratePercent}%',
                l10n.habitPerfectDays(insights.grid.where((v) => v != null && v >= 1).length),
              ].join(', '),
              excludeSemantics: true,
              child: _MonthGrid(grid: insights.grid, today: todayMidnight, dark: dark),
            ),
          ),
          const SizedBox(height: 10),
          DeenCard(
            dark: dark,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.habitWeekProgress(insights.weekDone, insights.weekDue),
                  style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark)),
                ),
                const SizedBox(height: 10),
                _WeekBars(
                  dayCounts: dayCounts,
                  dark: dark,
                  dayLabels: [
                    for (var i = 0; i < 7; i++)
                      '${formatShortDate(l10n.localeName, DateTime(monday.year, monday.month, monday.day + i))}, '
                          '${dayCounts[i] == 0 ? l10n.noHabitsCompletedOnDay : l10n.habitsCompletedOnDay(dayCounts[i])}',
                  ],
                  onTapDay: (i) => _showDayDetail(
                    context,
                    l10n,
                    dark,
                    DateTime(monday.year, monday.month, monday.day + i),
                    insights.weekDoneTitles[i],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DeenCard(
            dark: dark,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.habitMilestonesLabel, style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final days in kInsightMilestoneDays)
                      Expanded(child: _MilestoneBadge(days: days, reached: insights.reached(days), dark: dark)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four Mon-Sun rows, oldest at the top, shaded by how much of that day's
/// habits got done. Today gets a gold outline; days still to come are blank.
class _MonthGrid extends StatelessWidget {
  final List<double?> grid;
  final DateTime today;
  final bool dark;

  const _MonthGrid({required this.grid, required this.today, required this.dark});

  /// A heat scale has to read in order: every "some done" shade must sit
  /// past the empty one. [DeenColors.statsEmpty] can't be the empty square
  /// here - measured, it's *brighter* than a lightly-filled day in dark mode
  /// (and darker than one in light), so a quarter-done day looked like less
  /// than nothing. Empty gets its own much fainter tint instead, and the
  /// fill steps up in thirds.
  /// On the full-strength fill, in the same colour as the tick on an
  /// on-time prayer: white in light mode (7:1), ink in dark (5.1:1). In the
  /// legend it sits on the card, where that ink would vanish in dark mode,
  /// so it's drawn filled-circle style there too.
  Widget _perfectStar(double size) => Container(
        width: size + 3,
        height: size + 3,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: DeenColors.statsFill(dark), shape: BoxShape.circle),
        child: Icon(Icons.star_rounded, size: size - 1, color: DeenColors.onPrayerOnTime(dark)),
      );

  Color _shade(double? done) {
    final card = DeenColors.cardBackground(dark);
    if (done == null || done == 0) {
      return Color.alphaBlend((dark ? Colors.white : DeenColors.primary).withValues(alpha: 0.08), card);
    }
    final alpha = done >= 1 ? 1.0 : (done > 2 / 3 ? 0.8 : (done > 1 / 3 ? 0.6 : 0.35));
    return Color.alphaBlend(DeenColors.statsFill(dark).withValues(alpha: alpha), card);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = TextStyle(fontSize: 10.5, color: DeenColors.textMuted(dark));
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final gridStart = DateTime(monday.year, monday.month, monday.day - 7 * (kInsightGridWeeks - 1));
    final weekday = DateFormat.E(l10n.localeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  weekday.format(DateTime(monday.year, monday.month, monday.day + i)),
                  textAlign: TextAlign.center,
                  style: muted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var w = 0; w < kInsightGridWeeks; w++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: AspectRatio(
                        aspectRatio: 1.6,
                        child: Builder(builder: (context) {
                          final index = w * 7 + d;
                          final day = DateTime(gridStart.year, gridStart.month, gridStart.day + index);
                          final future = day.isAfter(today);
                          final perfect = !future && (grid[index] ?? 0) >= 1;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: future ? Colors.transparent : _shade(grid[index]),
                              borderRadius: BorderRadius.circular(4),
                              border: day == today
                                  ? Border.all(color: DeenColors.prayerLate(dark), width: 1.5)
                                  : (future ? Border.all(color: DeenColors.statsOutline(dark)) : null),
                            ),
                            // A day with every due habit done gets a star -
                            // celebrated when it happens, never counted as a
                            // score that sits at zero.
                            child: perfect ? Center(child: _perfectStar(13)) : null,
                          );
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            _perfectStar(12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(l10n.habitPerfectDayLegend, style: muted, overflow: TextOverflow.ellipsis),
            ),
            Text(l10n.habitGridLess, style: muted),
            const SizedBox(width: 5),
            for (final v in const [0.0, 0.3, 0.6, 0.9, 1.0]) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: _shade(v), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 3),
            ],
            const SizedBox(width: 2),
            Text(l10n.habitGridMore, style: muted),
          ],
        ),
      ],
    );
  }
}

class _MilestoneBadge extends StatelessWidget {
  final int days;
  final bool reached;
  final bool dark;

  const _MilestoneBadge({required this.days, required this.reached, required this.dark});

  static const _icons = {
    7: Icons.spa_outlined,
    30: Icons.nightlight_round,
    40: Icons.star_rounded,
    100: Icons.workspace_premium_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Earned reads as filled with a bolder label; not yet earned is an
    // outlined ring with a muted label. No opacity on either: faded text at
    // 45% measured about 2:1, under the 4.5:1 text needs.
    return Semantics(
      label: reached ? l10n.habitMilestoneReached(days) : l10n.habitMilestoneNotReached(days),
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached ? DeenColors.statsFill(dark) : null,
              border: reached ? null : Border.all(color: DeenColors.statsOutline(dark), width: 1.5),
            ),
            child: Icon(
              _icons[days] ?? Icons.star_rounded,
              size: 20,
              color: reached ? DeenColors.onPrayerOnTime(dark) : DeenColors.textMuted(dark),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.habitMilestoneDays(days),
            style: TextStyle(
              fontSize: 11,
              fontWeight: reached ? FontWeight.w600 : FontWeight.w400,
              color: reached ? DeenColors.primaryText(dark) : DeenColors.textMuted(dark),
            ),
          ),
        ],
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
  static const _maxBarHeight = 56.0;

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
      // wide gaps. 70% of the slot (about 35dp on a phone) keeps them
      // chunky with a clear gap between days; the cap stops them turning
      // into blocks on a tablet.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = (constraints.maxWidth / 7 * 0.7).clamp(6.0, 44.0);
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
                                  ? DeenColors.statsOutline(dark)
                                  : (dark ? DeenColors.goldSoft : DeenColors.primary),
                              borderRadius: BorderRadius.circular(6),
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
