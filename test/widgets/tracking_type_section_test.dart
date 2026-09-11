import 'package:deenroutine/l10n/app_localizations.dart';
import 'package:deenroutine/models/habit.dart';
import 'package:deenroutine/widgets/tracking_type_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the tracking-type picker overflowing on the
/// add/edit habit screen. It used to sit in a GridView.count with a fixed
/// childAspectRatio, which locked every card to an exact height - a longer
/// label (a larger system font-scale setting, or just a language whose word
/// for a given type runs longer) needed more room than that budget allowed,
/// throwing a RenderFlex overflow. Reproducing that needs a narrow width
/// plus a bumped text scale, since the English labels are normally short
/// enough to fit either dimension alone.
void main() {
  Future<void> pumpPicker(
    WidgetTester tester, {
    required HabitTrackingType selected,
    required Locale locale,
    required double textScale,
    required double width,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: TrackingTypePicker(selected: selected, onChanged: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'every tracking type card renders without overflowing at 1.8x text scale on a narrow phone ($locale)',
      (tester) async {
        for (final type in HabitTrackingType.values) {
          await pumpPicker(tester, selected: type, locale: locale, textScale: 1.8, width: 360);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Tracking type "$type" overflowed at 1.8x text scale ($locale)',
          );
        }
      },
    );
  }

  testWidgets('tracking type cards render without overflowing at normal text scale',
      (tester) async {
    for (final type in HabitTrackingType.values) {
      await pumpPicker(tester, selected: type, locale: const Locale('en'), textScale: 1.0, width: 360);
      expect(tester.takeException(), isNull, reason: 'Tracking type "$type" overflowed');
    }
  });
}
