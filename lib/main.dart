import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Analytics is opt-in (see AnalyticsProvider) — collection defaults to on
  // at the SDK level, so this closes the window before the saved choice
  // loads. AnalyticsProvider only ever turns this back on, never assumes
  // it's already off. Wrapped so a device-specific Analytics failure (e.g.
  // no Google Play Services) can't take the whole app down before it renders.
  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
  } catch (e) {
    debugPrint('Analytics collection toggle failed: $e');
  }

  // Same reasoning: a notification-init failure shouldn't block the app
  // from rendering at all — worse than losing reminders is losing the app.
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }

  runApp(const DeenRoutineApp());
}
