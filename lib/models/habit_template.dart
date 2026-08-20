import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'habit.dart';

/// A starter habit offered by the template picker so someone doesn't have to
/// type a title from scratch. Purely a Dart list — unlike [Habit] this has no
/// Firestore representation; picking one just pre-fills the add-habit form
/// the same way editing an existing habit does.
class HabitTemplate {
  final String title;
  final HabitCategory category;
  final HabitFrequency frequency;
  final IconData icon;

  const HabitTemplate({
    required this.title,
    required this.category,
    required this.frequency,
    required this.icon,
  });
}

/// Starter habits shown by the template picker, grouped by [HabitCategory]
/// in the UI. To add one: add a `templateX` key to both .arb files, then an
/// entry here — no seed script or content release beyond a normal app build.
List<HabitTemplate> habitTemplates(AppLocalizations l10n) => [
      HabitTemplate(
        title: l10n.templatePrayFiveTimes,
        category: HabitCategory.islam,
        frequency: HabitFrequency.daily,
        icon: Icons.nights_stay_outlined,
      ),
      HabitTemplate(
        title: l10n.templateReadQuran,
        category: HabitCategory.islam,
        frequency: HabitFrequency.daily,
        icon: Icons.menu_book_outlined,
      ),
      HabitTemplate(
        title: l10n.templateDhikrAfterPrayer,
        category: HabitCategory.islam,
        frequency: HabitFrequency.daily,
        icon: Icons.self_improvement,
      ),
      HabitTemplate(
        title: l10n.templateDrinkWater,
        category: HabitCategory.lifestyle,
        frequency: HabitFrequency.daily,
        icon: Icons.water_drop_outlined,
      ),
      HabitTemplate(
        title: l10n.templateSleepEarly,
        category: HabitCategory.lifestyle,
        frequency: HabitFrequency.daily,
        icon: Icons.bedtime_outlined,
      ),
      HabitTemplate(
        title: l10n.templateShortWalk,
        category: HabitCategory.lifestyle,
        frequency: HabitFrequency.daily,
        icon: Icons.directions_walk_outlined,
      ),
      HabitTemplate(
        title: l10n.templateReadPages,
        category: HabitCategory.learn,
        frequency: HabitFrequency.daily,
        icon: Icons.auto_stories_outlined,
      ),
      HabitTemplate(
        title: l10n.templateLearnNewWord,
        category: HabitCategory.learn,
        frequency: HabitFrequency.daily,
        icon: Icons.translate_outlined,
      ),
      HabitTemplate(
        title: l10n.templateWatchEducationalVideo,
        category: HabitCategory.learn,
        frequency: HabitFrequency.daily,
        icon: Icons.ondemand_video_outlined,
      ),
      HabitTemplate(
        title: l10n.templateDeepWorkBlock,
        category: HabitCategory.work,
        frequency: HabitFrequency.daily,
        icon: Icons.work_outline,
      ),
      HabitTemplate(
        title: l10n.templateInboxZero,
        category: HabitCategory.work,
        frequency: HabitFrequency.daily,
        icon: Icons.inbox_outlined,
      ),
      HabitTemplate(
        title: l10n.templatePlanTomorrow,
        category: HabitCategory.work,
        frequency: HabitFrequency.daily,
        icon: Icons.event_note_outlined,
      ),
    ];
