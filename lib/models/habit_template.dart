import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'habit.dart';

/// A starter habit offered by the template picker so someone doesn't have to
/// type a title from scratch. Purely a Dart list — unlike [Habit] this has no
/// Firestore representation; picking one just pre-fills the add-habit form
/// the same way editing an existing habit does.
class HabitTemplate {
  /// Stable, locale-independent identifier (unlike [title], which is
  /// localized text) — used only to name which template was picked in
  /// analytics events.
  final String id;
  final String title;
  final HabitCategory category;
  final HabitFrequency frequency;
  final IconData icon;

  /// Tracking config a habit created from this template starts with. Left at
  /// the [Habit] defaults (yesNo, empty/1/10) for templates whose title
  /// doesn't spell out a specific count, duration, or item list.
  final HabitTrackingType trackingType;
  final List<String> checklistItems;
  final int numericTarget;
  final String numericUnit;
  final int timerTargetMinutes;

  const HabitTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.frequency,
    required this.icon,
    this.trackingType = HabitTrackingType.yesNo,
    this.checklistItems = const [],
    this.numericTarget = 1,
    this.numericUnit = '',
    this.timerTargetMinutes = 10,
  });
}

/// Starter habits shown by the template picker, grouped by [HabitCategory]
/// in the UI. To add one: add a `templateX` key to both .arb files, then an
/// entry here — no seed script or content release beyond a normal app build.
List<HabitTemplate> habitTemplates(AppLocalizations l10n) => [
      HabitTemplate(
        id: 'pray_five_times',
        title: l10n.templatePrayFiveTimes,
        category: HabitCategory.islam,
        frequency: HabitFrequency.daily,
        icon: Icons.nights_stay_outlined,
        trackingType: HabitTrackingType.checklist,
        checklistItems: [
          l10n.prayerFajr,
          l10n.prayerDhuhr,
          l10n.prayerAsr,
          l10n.prayerMaghrib,
          l10n.prayerIsha,
        ],
      ),
      HabitTemplate(
        id: 'read_quran',
        title: l10n.templateReadQuran,
        category: HabitCategory.islam,
        frequency: HabitFrequency.daily,
        icon: Icons.menu_book_outlined,
      ),
      HabitTemplate(
        id: 'dhikr_after_prayer',
        title: l10n.templateDhikrAfterPrayer,
        category: HabitCategory.islam,
        frequency: HabitFrequency.daily,
        icon: Icons.self_improvement,
      ),
      HabitTemplate(
        id: 'drink_water',
        title: l10n.templateDrinkWater,
        category: HabitCategory.lifestyle,
        frequency: HabitFrequency.daily,
        icon: Icons.water_drop_outlined,
      ),
      HabitTemplate(
        id: 'sleep_early',
        title: l10n.templateSleepEarly,
        category: HabitCategory.lifestyle,
        frequency: HabitFrequency.daily,
        icon: Icons.bedtime_outlined,
      ),
      HabitTemplate(
        id: 'short_walk',
        title: l10n.templateShortWalk,
        category: HabitCategory.lifestyle,
        frequency: HabitFrequency.daily,
        icon: Icons.directions_walk_outlined,
        trackingType: HabitTrackingType.timer,
        timerTargetMinutes: 10,
      ),
      HabitTemplate(
        id: 'read_pages',
        title: l10n.templateReadPages,
        category: HabitCategory.learn,
        frequency: HabitFrequency.daily,
        icon: Icons.auto_stories_outlined,
        trackingType: HabitTrackingType.numeric,
        numericTarget: 20,
        numericUnit: 'pages',
      ),
      HabitTemplate(
        id: 'learn_new_word',
        title: l10n.templateLearnNewWord,
        category: HabitCategory.learn,
        frequency: HabitFrequency.daily,
        icon: Icons.translate_outlined,
      ),
      HabitTemplate(
        id: 'watch_educational_video',
        title: l10n.templateWatchEducationalVideo,
        category: HabitCategory.learn,
        frequency: HabitFrequency.daily,
        icon: Icons.ondemand_video_outlined,
      ),
      HabitTemplate(
        id: 'deep_work_block',
        title: l10n.templateDeepWorkBlock,
        category: HabitCategory.work,
        frequency: HabitFrequency.daily,
        icon: Icons.work_outline,
      ),
      HabitTemplate(
        id: 'inbox_zero',
        title: l10n.templateInboxZero,
        category: HabitCategory.work,
        frequency: HabitFrequency.daily,
        icon: Icons.inbox_outlined,
      ),
      HabitTemplate(
        id: 'plan_tomorrow',
        title: l10n.templatePlanTomorrow,
        category: HabitCategory.work,
        frequency: HabitFrequency.daily,
        icon: Icons.event_note_outlined,
      ),
    ];
