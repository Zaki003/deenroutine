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
  // it's already off.
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);

  await NotificationService().init();

  runApp(const DeenRoutineApp());
}
