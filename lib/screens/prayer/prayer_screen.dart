import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/prayer_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/duration_format.dart';
import '../../utils/prayer_error_messages.dart';
import '../../utils/prayer_labels.dart';
import '../../widgets/gradient_hero_card.dart';

/// Dedicated Prayer Times tab: a day-progress bar between Fajr and Isha,
/// the next-prayer hero, and the remaining prayers for today.
class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;

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
                const Icon(Icons.public_rounded, size: 12, color: DeenColors.textMuted),
                const SizedBox(width: 4),
                Text(l10n.prayerMethodFullName,
                    style: const TextStyle(fontSize: 11.5, color: DeenColors.textMuted)),
              ],
            ),
            const SizedBox(height: 20),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.hasError)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.prayerTimesUnavailable(
                      prayerErrorMessage(l10n, provider.errorType!, provider.errorDetail)),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else if (provider.timings.isEmpty)
              const SizedBox.shrink()
            else ...[
              _DayProgress(timings: provider.timings, nextPrayer: provider.nextPrayerName!, dark: dark),
              const SizedBox(height: 16),
              GradientHeroCard(
                eyebrow: l10n.nextPrayerLabel,
                prayerName: prayerNameLabel(l10n, provider.nextPrayerName!),
                timeLabel: provider.nextPrayerTime ?? '',
                remainingLabel: provider.timeUntilNextPrayer != null
                    ? l10n.prayerRemainingLong(formatCountdown(provider.timeUntilNextPrayer!))
                    : '',
              ),
              const SizedBox(height: 16),
              for (final entry in _otherPrayers(provider))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: DeenColors.cardBackground(dark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DeenColors.cardBorder(dark)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Opacity(
                          opacity: entry.passed ? 0.5 : 1,
                          child: Text(
                            prayerNameLabel(l10n, entry.key),
                            style: TextStyle(
                              fontSize: 13.5,
                              color: DeenColors.primaryText(dark),
                            ),
                          ),
                        ),
                        Text(entry.value,
                            style: const TextStyle(fontSize: 13, color: DeenColors.textMuted)),
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
  final bool dark;

  const _DayProgress({required this.timings, required this.nextPrayer, required this.dark});

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
                          _Dot(active: i == nextIndex, passed: i <= nextIndex, dark: dark),
                          const SizedBox(height: 4),
                          Text(
                            prayerNameLabel(l10n, keys[i]),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: i == nextIndex ? FontWeight.bold : FontWeight.w500,
                              color: i == nextIndex ? DeenColors.gold : DeenColors.textMuted,
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

class _Dot extends StatelessWidget {
  final bool active;
  final bool passed;
  final bool dark;

  const _Dot({required this.active, required this.passed, required this.dark});

  @override
  Widget build(BuildContext context) {
    final size = active ? 14.0 : 10.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: passed ? DeenColors.gold : DeenColors.cardBackground(dark),
        border: Border.all(
          color: passed ? DeenColors.gold : DeenColors.outlineFaint(dark),
          width: 2,
        ),
      ),
    );
  }
}
