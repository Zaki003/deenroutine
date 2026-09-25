import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/prayer_log.dart';
import '../../providers/prayer_log_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/prayer_labels.dart';
import '../../utils/prayer_log_error_messages.dart';
import '../../utils/prayer_stats.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/stat_tile.dart';

/// The Profile's "Prayer insights": a collapsed header that opens into the
/// last-30-days prayer summary - three headline numbers, a bar per prayer, a
/// nudge for the hardest one, and a day-by-day grid.
///
/// Collapsed by default because it's the most personal thing in the app and
/// the Profile is the screen people show others; the header itself carries
/// no numbers. Whether it's open is remembered per device, and the history
/// is only fetched once it's opened, so a closed section costs no reads.
/// No share action, unlike the habit stats.
class PrayerStatsSection extends StatefulWidget {
  const PrayerStatsSection({super.key});

  @override
  State<PrayerStatsSection> createState() => _PrayerStatsSectionState();
}

class _PrayerStatsSectionState extends State<PrayerStatsSection> {
  static const _expandedKey = 'profile_prayer_insights_expanded';

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted || !(prefs.getBool(_expandedKey) ?? false)) return;
      setState(() => _expanded = true);
      _loadHistory();
    });
  }

  // loadHistory notifies when it finishes, so it's kicked off after the
  // frame rather than from a build. It's a no-op once loaded for the day.
  void _loadHistory() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PrayerLogProvider>().loadHistory();
      });

  Future<void> _toggle() async {
    setState(() => _expanded = !_expanded);
    if (_expanded) _loadHistory();
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
                    Icon(Icons.mosque_outlined, size: 22, color: dark ? DeenColors.goldSoft : DeenColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.prayerInsightsTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DeenColors.primaryText(dark),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.prayerInsightsSubtitle,
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
            child: _expanded ? const _PrayerInsightsBody() : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _PrayerInsightsBody extends StatelessWidget {
  const _PrayerInsightsBody();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<PrayerLogProvider>();
    final prayer = context.watch<PrayerProvider>();
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final stats = logs.stats;

    if (stats == null) {
      final Widget child;
      if (logs.errorType == PrayerLogErrorType.historyFailed) {
        child = Text(
          prayerLogErrorMessage(l10n, PrayerLogErrorType.historyFailed),
          style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark)),
        );
      } else if (!logs.historyLoaded) {
        child = Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: dark ? DeenColors.goldSoft : DeenColors.primary,
            ),
          ),
        );
      } else {
        child = Text(
          l10n.prayerInsightsEmpty,
          style: TextStyle(fontSize: 12.5, height: 1.4, color: DeenColors.textMuted(dark)),
        );
      }
      return Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 0), child: child);
    }

    String pct(int? p) => p == null ? '—' : '$p%';
    final weakest = stats.weakestPrayer;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: l10n.prayerStreakLabel,
                  value: stats.streakCapped ? '${stats.streak}+' : '${stats.streak}',
                  dark: dark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: l10n.prayerPrayedLabel, value: pct(stats.prayedPercent), dark: dark)),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: l10n.prayerOptionOnTime, value: pct(stats.onTimePercent), dark: dark)),
            ],
          ),
          const SizedBox(height: 10),
          DeenCard(
            dark: dark,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                for (final key in PrayerLog.prayerKeys)
                  _PrayerBar(
                    name: prayerNameLabel(l10n, key),
                    percent: stats.perPrayerPercent[key],
                    highlight: key == weakest,
                    dark: dark,
                  ),
              ],
            ),
          ),
          if (weakest != null) ...[
            const SizedBox(height: 10),
            _WeakestInsight(
              prayerName: prayerNameLabel(l10n, weakest),
              alarmOn: prayer.notifyEnabled(weakest),
              onTurnOnAlarm: () => prayer.toggleNotify(weakest),
              dark: dark,
            ),
          ],
          const SizedBox(height: 10),
          DeenCard(
            dark: dark,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            // The bars above already say the same thing per prayer, so the
            // grid is left out for screen readers rather than read as 150
            // unlabelled squares.
            child: ExcludeSemantics(child: _PrayerGrid(stats: stats, dark: dark)),
          ),
        ],
      ),
    );
  }
}

class _PrayerBar extends StatelessWidget {
  final String name;
  final int? percent;
  final bool highlight;
  final bool dark;

  const _PrayerBar({required this.name, required this.percent, required this.highlight, required this.dark});

  @override
  Widget build(BuildContext context) {
    final value = (percent ?? 0) / 100;
    return Semantics(
      label: '$name: ${percent == null ? '—' : '$percent%'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: TextStyle(fontSize: 12.5, color: DeenColors.primaryText(dark))),
                Text(
                  percent == null ? '—' : '$percent%',
                  style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: DeenColors.prayerEmpty(dark),
                  // The hardest prayer is gold, never red.
                  valueColor: AlwaysStoppedAnimation(
                    highlight ? DeenColors.prayerLate(dark) : DeenColors.prayerOnTime(dark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakestInsight extends StatelessWidget {
  final String prayerName;
  final bool alarmOn;
  final VoidCallback onTurnOnAlarm;
  final bool dark;

  const _WeakestInsight({
    required this.prayerName,
    required this.alarmOn,
    required this.onTurnOnAlarm,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DeenCard(
      dark: dark,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Icon(Icons.wb_twilight_rounded, size: 18, color: DeenColors.prayerLate(dark)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alarmOn ? l10n.prayerWeakestInsightPlain(prayerName) : l10n.prayerWeakestInsight(prayerName),
              style: TextStyle(fontSize: 12.5, color: DeenColors.primaryText(dark)),
            ),
          ),
          if (!alarmOn)
            TextButton(
              onPressed: onTurnOnAlarm,
              child: Text(l10n.prayerTurnOnAlarm, style: TextStyle(color: DeenColors.primaryText(dark))),
            ),
        ],
      ),
    );
  }
}

/// Five rows of [PrayerStats.windowDays] squares, oldest day on the left.
/// Missed, excused and unlogged all share the same neutral square - the grid
/// is visible to anyone glancing at the phone, so it never shows why a
/// prayer wasn't prayed.
class _PrayerGrid extends StatelessWidget {
  final PrayerStats stats;
  final bool dark;

  const _PrayerGrid({required this.stats, required this.dark});

  Color _colorFor(PrayerStatus? status) => switch (status) {
        PrayerStatus.onTime => DeenColors.prayerOnTime(dark),
        PrayerStatus.late => DeenColors.prayerLate(dark),
        PrayerStatus.qada => DeenColors.prayerQada(dark),
        _ => DeenColors.prayerEmpty(dark),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = TextStyle(fontSize: 10.5, color: DeenColors.textMuted(dark));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in PrayerLog.prayerKeys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(prayerNameLabel(l10n, key), style: muted, overflow: TextOverflow.ellipsis),
                ),
                for (final status in stats.grid[key]!)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.75),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _colorFor(status),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _legend(_colorFor(PrayerStatus.onTime), l10n.prayerOptionOnTime, muted),
            _legend(_colorFor(PrayerStatus.late), l10n.prayerOptionLate, muted),
            _legend(_colorFor(PrayerStatus.qada), l10n.prayerLegendQada, muted),
            _legend(_colorFor(null), l10n.prayerLegendNotLogged, muted),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label, TextStyle style) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Text(label, style: style),
        ],
      );
}
