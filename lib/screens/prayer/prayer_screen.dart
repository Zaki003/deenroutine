import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/prayer_log.dart';
import '../../providers/prayer_log_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/duration_format.dart';
import '../../utils/prayer_error_messages.dart';
import '../../utils/prayer_labels.dart';
import '../../utils/prayer_log_error_messages.dart';
import '../../utils/prayer_method_labels.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/gradient_hero_card.dart';
import '../../widgets/section_label.dart';
import '../../widgets/update_location_action.dart';

/// Dedicated Prayer Times tab: a day-progress bar between Fajr and Isha,
/// the next-prayer hero, and the remaining prayers for today, each with a
/// tick circle to log it. The next prayer has none - by definition it
/// hasn't started, so there's nothing to log yet.
class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final logs = context.watch<PrayerLogProvider>();
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final needsSettings =
        provider.hasError && prayerErrorNeedsSettings(provider.errorType!);

    return ColoredBox(
      color: DeenColors.surface(dark),
      child: RefreshIndicator(
        onRefresh: () => provider.loadPrayerTimes(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              l10n.prayerScreenTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DeenColors.primaryText(dark),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.public_rounded, size: 12, color: DeenColors.textMuted(dark)),
                const SizedBox(width: 4),
                Text(prayerMethodLabel(l10n, provider.calculationMethod),
                    style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark))),
              ],
            ),
            const SizedBox(height: 20),
            if (provider.isLoading)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: DeenColors.gold),
                ),
              )
            else if (provider.hasError)
              EmptyStateCard(
                icon: Icons.cloud_off_rounded,
                iconColor: DeenColors.rust,
                title: l10n.prayerUnavailableTitle,
                message: prayerErrorMessage(l10n, provider.errorType!, provider.errorDetail),
                dark: dark,
                compact: true,
                actionLabel: needsSettings ? l10n.openSettingsButton : l10n.retryButton,
                onAction: needsSettings
                    ? () => provider.openSettingsForCurrentError()
                    : () => provider.loadPrayerTimes(),
              )
            else if (provider.timings.isEmpty)
              const SizedBox.shrink()
            else ...[
              _DayProgress(
                timings: provider.timings,
                nextPrayer: provider.nextPrayerName!,
                statuses: logs.isAvailable
                    ? {for (final key in provider.timings.keys) key: logs.statusFor(key)}
                    : null,
                dark: dark,
              ),
              const SizedBox(height: 16),
              GradientHeroCard(
                eyebrow: l10n.nextPrayerLabel,
                prayerName: prayerNameLabel(l10n, provider.nextPrayerName!),
                timeLabel: provider.nextPrayerTime ?? '',
                remainingLabel: provider.timeUntilNextPrayer != null
                    ? l10n.prayerRemainingLong(formatCountdown(provider.timeUntilNextPrayer!))
                    : '',
                onUpdateLocation: () => confirmUpdateLocation(context),
                notifyEnabled: provider.notifyEnabled(provider.nextPrayerName!),
                onToggleNotify: () => provider.toggleNotify(provider.nextPrayerName!),
              ),
              const SizedBox(height: 16),
              if (logs.isAvailable) ...[
                SectionLabel(logs.prayerDayIsYesterday
                    ? l10n.prayerDayYesterdayProgress(logs.prayedCount)
                    : l10n.prayerDayTodayProgress(logs.prayedCount)),
                if (logs.errorType == PrayerLogErrorType.syncFailed) ...[
                  const SizedBox(height: 2),
                  Text(
                    prayerLogErrorMessage(l10n, PrayerLogErrorType.syncFailed),
                    style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark)),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              for (final entry in _otherPrayers(provider))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    // The tick's own 48px tap target supplies the row's height
                    // when tracking is on.
                    padding: logs.isAvailable
                        ? const EdgeInsets.fromLTRB(16, 2, 4, 2)
                        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: DeenColors.cardBackground(dark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DeenColors.cardBorder(dark)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: entry.passed && logs.statusFor(entry.key) == null ? 0.5 : 1,
                                child: Text(
                                  prayerNameLabel(l10n, entry.key),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: DeenColors.primaryText(dark),
                                  ),
                                ),
                              ),
                              if (logs.statusFor(entry.key) case final status?)
                                Text(
                                  prayerStatusLabel(l10n, status),
                                  style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark)),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(entry.value,
                                style: TextStyle(fontSize: 13, color: DeenColors.textMuted(dark))),
                            const SizedBox(width: 4),
                            _NotifyBell(
                              enabled: provider.notifyEnabled(entry.key),
                              dark: dark,
                              onTap: () => provider.toggleNotify(entry.key),
                            ),
                            if (logs.isAvailable) ...[
                              const SizedBox(width: 4),
                              _PrayerTick(
                                prayerName: prayerNameLabel(l10n, entry.key),
                                status: logs.statusFor(entry.key),
                                enabled: logs.canLog(entry.key),
                                dark: dark,
                                onTap: () => _toggle(context, logs, entry.key),
                                onLongPress: () => _showStatusSheet(context, logs, entry.key),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Tap: log it now (the clock decides on time / late / qada), or undo an
  /// existing log.
  Future<void> _toggle(BuildContext context, PrayerLogProvider logs, String prayerKey) async {
    final ok = logs.statusFor(prayerKey) == null
        ? await logs.logNow(prayerKey)
        : await logs.setStatus(prayerKey, null);
    if (!ok && context.mounted) _showSaveError(context, logs);
  }

  void _showSaveError(BuildContext context, PrayerLogProvider logs) {
    final type = logs.errorType;
    if (type == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(prayerLogErrorMessage(AppLocalizations.of(context)!, type))),
    );
  }

  /// Hold: pick a status by hand - for logging a prayer some time after
  /// praying it, or correcting what a tap decided. Late is only offered for
  /// the prayers that have a late window at all.
  void _showStatusSheet(BuildContext context, PrayerLogProvider logs, String prayerKey) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final current = logs.statusFor(prayerKey);
    final hasLate = logs.windowFor(prayerKey)?.hasLateWindow ?? false;
    final options = [
      PrayerStatus.onTime,
      if (hasLate) PrayerStatus.late,
      PrayerStatus.qada,
      PrayerStatus.missed,
    ];

    Future<void> choose(BuildContext sheetContext, PrayerStatus? status) async {
      Navigator.pop(sheetContext);
      final ok = await logs.setStatus(prayerKey, status);
      if (!ok && context.mounted) _showSaveError(context, logs);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: DeenColors.cardBackground(dark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.prayerLogSheetTitle(prayerNameLabel(l10n, prayerKey)),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DeenColors.primaryText(dark),
                  ),
                ),
              ),
              for (final option in options)
                ListTile(
                  leading: _StatusCircle(status: option, enabled: true, dark: dark, size: 26),
                  title: Text(
                    prayerOptionLabel(l10n, option),
                    style: TextStyle(fontSize: 14, color: DeenColors.primaryText(dark)),
                  ),
                  trailing: option == current
                      ? Icon(Icons.check_rounded, color: DeenColors.primaryText(dark))
                      : null,
                  selected: option == current,
                  onTap: () => choose(sheetContext, option),
                ),
              if (current != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => choose(sheetContext, null),
                    child: Text(l10n.prayerOptionClear,
                        style: TextStyle(color: DeenColors.primaryText(dark))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<({String key, String value, bool passed})> _otherPrayers(PrayerProvider provider) {
    final entries = provider.timings.entries.toList();
    final nextIndex = entries.indexWhere((e) => e.key == provider.nextPrayerName);
    return [
      for (var i = 0; i < entries.length; i++)
        if (i != nextIndex)
          (key: entries[i].key, value: entries[i].value, passed: i < nextIndex),
    ];
  }
}

class _DayProgress extends StatelessWidget {
  final Map<String, String> timings;
  final String nextPrayer;

  /// Each prayer's log for the current prayer day, or null while tracking
  /// isn't available - the dots then just follow the clock, as before.
  final Map<String, PrayerStatus?>? statuses;
  final bool dark;

  const _DayProgress({
    required this.timings,
    required this.nextPrayer,
    required this.statuses,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keys = timings.keys.toList();
    final nextIndex = keys.indexOf(nextPrayer);

    return LayoutBuilder(
      builder: (context, constraints) {
        final segment = constraints.maxWidth / keys.length;
        final lineProgress = keys.length > 1 ? nextIndex / (keys.length - 1) : 0.0;
        return SizedBox(
          height: 46,
          child: Stack(
            children: [
              Positioned(
                left: segment / 2,
                right: segment / 2,
                top: 4,
                child: Container(height: 2, color: DeenColors.trackLine(dark)),
              ),
              Positioned(
                left: segment / 2,
                width: (constraints.maxWidth - segment) * lineProgress,
                top: 4,
                child: Container(height: 2, color: DeenColors.gold),
              ),
              Row(
                children: [
                  for (var i = 0; i < keys.length; i++)
                    SizedBox(
                      width: segment,
                      child: Column(
                        children: [
                          _Dot(
                            active: i == nextIndex,
                            // With tracking on, a dot fills in when its prayer
                            // is logged rather than when its time passes.
                            passed: statuses == null && i <= nextIndex,
                            status: statuses?[keys[i]],
                            dark: dark,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            prayerNameLabel(l10n, keys[i]),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: i == nextIndex ? FontWeight.bold : FontWeight.w500,
                              color: i == nextIndex ? DeenColors.gold : DeenColors.textMuted(dark),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact bell toggle for one prayer row - see [GradientHeroCard]'s own
/// bell for the highlighted next-prayer version of the same control.
class _NotifyBell extends StatelessWidget {
  final bool enabled;
  final bool dark;
  final VoidCallback onTap;

  const _NotifyBell({required this.enabled, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      onPressed: onTap,
      icon: Icon(enabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined),
      iconSize: 16,
      color: enabled ? DeenColors.gold : DeenColors.textMuted(dark),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      tooltip: enabled ? l10n.prayerNotifyOnTooltip : l10n.prayerNotifyOffTooltip,
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final bool passed;
  final PrayerStatus? status;
  final bool dark;

  const _Dot({required this.active, required this.passed, required this.status, required this.dark});

  @override
  Widget build(BuildContext context) {
    final size = active ? 14.0 : 10.0;
    final fill = switch (status) {
      PrayerStatus.onTime => DeenColors.prayerOnTime(dark),
      PrayerStatus.late => DeenColors.prayerLate,
      PrayerStatus.qada => DeenColors.prayerQada(dark),
      PrayerStatus.missed || null => passed ? DeenColors.gold : null,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill ?? DeenColors.cardBackground(dark),
        border: Border.all(
          color: fill ?? (active ? DeenColors.gold : DeenColors.outlineFaint(dark)),
          width: 2,
        ),
      ),
    );
  }
}

/// A prayer's log state as a filled circle: a tick for on time, a clock for
/// late, a rewind for qada, a dash for not prayed, and an empty ring while
/// unlogged. Each state has its own icon as well as its own colour, so they
/// stay distinguishable without colour vision.
class _StatusCircle extends StatelessWidget {
  final PrayerStatus? status;
  final bool enabled;
  final bool dark;
  final double size;

  const _StatusCircle({required this.status, required this.enabled, required this.dark, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final (Color? fill, Color? iconColor, IconData? icon) = switch (status) {
      PrayerStatus.onTime => (DeenColors.prayerOnTime(dark), Colors.white, Icons.check_rounded),
      PrayerStatus.late => (DeenColors.prayerLate, DeenColors.ink, Icons.schedule_rounded),
      PrayerStatus.qada => (DeenColors.prayerQada(dark), Colors.white, Icons.history_rounded),
      PrayerStatus.missed => (null, DeenColors.textMuted(dark), Icons.remove_rounded),
      null => (null, null, null),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: fill == null
            ? Border.all(
                color: enabled ? DeenColors.textMuted(dark) : DeenColors.outlineFaint(dark),
                width: 1.5,
              )
            : null,
      ),
      child: icon == null ? null : Icon(icon, size: size * 0.62, color: iconColor),
    );
  }
}

/// [_StatusCircle] with a 48px tap target: tap logs or undoes, hold opens
/// the status sheet. Disabled until the prayer's time has started.
class _PrayerTick extends StatelessWidget {
  final String prayerName;
  final PrayerStatus? status;
  final bool enabled;
  final bool dark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PrayerTick({
    required this.prayerName,
    required this.status,
    required this.enabled,
    required this.dark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = status != null
        ? prayerStatusLabel(l10n, status!)
        : (enabled ? null : l10n.prayerNotStartedYet);
    return Semantics(
      button: true,
      enabled: enabled,
      label: state == null ? prayerName : '$prayerName, $state',
      onTapHint: status == null ? l10n.prayerMarkHint : l10n.prayerUndoHint,
      onLongPressHint: l10n.prayerMoreOptionsHint,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        radius: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: _StatusCircle(status: status, enabled: enabled, dark: dark)),
        ),
      ),
    );
  }
}
