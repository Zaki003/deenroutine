import 'dart:ui' show Locale;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../firebase_options.dart';
import '../l10n/app_localizations.dart';
import '../models/prayer_log.dart';
import '../utils/prayer_check_in_plan.dart';
import '../utils/prayer_labels.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

/// How long the "Dhuhr logged · on time" confirmation stays before clearing
/// itself.
const _confirmationTimeout = Duration(seconds: 6);

/// Handles a check-in's Prayed and Later buttons. Runs on a background
/// isolate with nothing from the app loaded (the plugin starts one even when
/// the app is open), so it sets up Firebase itself and works only from the
/// notification's own payload - see [CheckInPayload].
@pragma('vm:entry-point')
Future<void> prayerCheckInActionHandler(NotificationResponse response) async {
  final payload = CheckInPayload.decode(response.payload);
  final id = response.id;
  if (payload == null || id == null) return;
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notification')),
  );
  final l10n = lookupAppLocalizations(Locale(payload.lang));

  try {
    switch (response.actionId) {
      case checkInLaterActionId:
        await _askAgainLater(plugin, l10n, id, payload);
      case checkInPrayedActionId:
        await _logPrayed(plugin, l10n, id, payload);
    }
  } catch (e) {
    // Nothing to show an error on; the prayer can still be logged in the app.
    debugPrint('Prayer check-in action failed: $e');
  }
}

Future<void> _askAgainLater(
  FlutterLocalNotificationsPlugin plugin,
  AppLocalizations l10n,
  int id,
  CheckInPayload payload,
) async {
  final when = DateTime.now().add(checkInLaterDelay);
  // No point asking once the prayer can only be qada.
  if (!when.isBefore(payload.lateEnd)) return;
  // The device's zone isn't set up on this isolate; an instant in UTC is the
  // same moment.
  tz_data.initializeTimeZones();
  final repeat = payload.asRepeat();
  await plugin.zonedSchedule(
    id: id,
    title: repeat.title,
    body: repeat.body,
    scheduledDate: tz.TZDateTime.from(when, tz.UTC),
    notificationDetails: NotificationDetails(
      android: NotificationService.prayerCheckInDetails(
        repeat.body,
        actions: NotificationService.checkInActions(
          prayedLabel: l10n.prayerCheckInPrayed,
          laterLabel: l10n.prayerCheckInLater,
          isRepeat: true,
        ),
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: repeat.encode(),
  );
}

Future<void> _logPrayed(
  FlutterLocalNotificationsPlugin plugin,
  AppLocalizations l10n,
  int id,
  CheckInPayload payload,
) async {
  final status = payload.statusAt(DateTime.now());
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  // On a fresh isolate the saved session is restored asynchronously, so wait
  // for the first auth event rather than reading currentUser straight away.
  final user = await FirebaseAuth.instance.authStateChanges().first;
  if (user == null) return;

  final firestore = FirestoreService();
  final day = PrayerLog.parseDayKey(payload.day);
  // Already logged (in the app, or on another device) wins over the tap.
  final existing = await firestore.getPrayerLog(user.uid, day);
  final logged = existing?.statusFor(payload.prayerKey);
  if (logged == null) {
    await firestore.setPrayerStatuses(user.uid, day, {payload.prayerKey: status});
  }

  final shown = logged ?? status;
  final name = prayerNameLabel(l10n, payload.prayerKey);
  final body = l10n.prayerCheckInLoggedBody;
  await plugin.show(
    id: id,
    title: l10n.prayerCheckInLogged(name, prayerShortStatusLabel(l10n, shown)),
    body: body,
    notificationDetails: NotificationDetails(
      android: NotificationService.prayerCheckInDetails(
        body,
        timeoutAfter: _confirmationTimeout.inMilliseconds,
      ),
    ),
  );
}
