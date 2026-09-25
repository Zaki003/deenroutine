import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// What a notification is for. Each kind gets its own Android channel, so a
/// user can mute one (say, the weekly summary) from system settings without
/// losing the others.
enum NotificationKind { reminder, dailyQuote, streak, weekly, comeback }

/// FR-08: Reminder notifications for scheduled habits and prayer times.
///
/// Note: flutter_local_notifications v20+ converted all method parameters
/// to named parameters (breaking change). This file targets that API.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    // Without this, tz.local defaults to UTC, so every reminder is
    // silently scheduled at the device's UTC offset instead of the time
    // the user actually picked.
    final deviceTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: initSettings);
  }

  /// Android 13+ requires this explicit runtime permission. Split out of
  /// [init] (which runs in `main()` before `runApp()`) so the OS prompt
  /// fires when onboarding's notification-priming screen calls this on
  /// "Allow notifications" — not silently at cold start before the user
  /// has seen any explanation.
  Future<bool?>? requestPermission() {
    return _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  AndroidNotificationDetails _androidDetails(
      NotificationKind kind, String body) {
    // Expanded, so a whole message is readable rather than just its first line.
    final style = BigTextStyleInformation(body);
    switch (kind) {
      case NotificationKind.reminder:
        return AndroidNotificationDetails(
          'deenroutine_reminders',
          'DeenRoutine Reminders',
          channelDescription: 'Habit and prayer time reminders',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: style,
        );
      case NotificationKind.dailyQuote:
        return AndroidNotificationDetails(
          'deenroutine_daily_quote',
          'Daily ayah & hadith',
          channelDescription: 'One ayah or hadith a day, at the time you choose',
          styleInformation: style,
        );
      case NotificationKind.streak:
        return AndroidNotificationDetails(
          'deenroutine_streak',
          'Streak reminders',
          channelDescription: 'An evening nudge when a streak is at risk',
          styleInformation: style,
        );
      case NotificationKind.weekly:
        return AndroidNotificationDetails(
          'deenroutine_weekly',
          'Weekly summary',
          channelDescription: 'A Friday look back at your week',
          styleInformation: style,
        );
      case NotificationKind.comeback:
        return AndroidNotificationDetails(
          'deenroutine_comeback',
          'Come-back messages',
          channelDescription: 'A gentle message after a few days away',
          styleInformation: style,
        );
    }
  }

  /// Schedules one notification at [when], replacing any pending one with the
  /// same [id]. A [when] already in the past is silently skipped.
  ///
  /// [exact] is for things the user timed themselves (a habit reminder), which
  /// should land on the minute. If the phone won't allow exact alarms it falls
  /// back to an approximate one - a reminder a few minutes late beats none.
  /// Everything else is approximate on purpose: it doesn't need to be
  /// to-the-minute, and works without the "Alarms & reminders" grant.
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required NotificationKind kind,
    bool exact = false,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    final details = NotificationDetails(
      android: _androidDetails(kind, body),
      iOS: const DarwinNotificationDetails(),
    );
    Future<void> go(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: mode,
        );

    if (!exact) {
      await go(AndroidScheduleMode.inexactAllowWhileIdle);
      return;
    }
    try {
      await go(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException {
      await go(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<Set<int>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return {for (final request in pending) request.id};
  }

  Future<void> cancelIds(Iterable<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }

  /// The daily ayah/hadith is scheduled as a rolling window of individual
  /// notifications rather than one repeating one, since a repeating
  /// notification would show the same text forever. Fixed IDs in a band far
  /// above anything a habit reminder or a prayer alarm can reach (see
  /// notification_plan.dart), so cancelling them never touches those.
  static const quoteNotificationIdBase = 2000000000;
  static const quoteNotificationSlots = 7;

  Future<void> scheduleQuoteNotification({
    required int slot,
    required DateTime when,
    required String title,
    required String body,
  }) =>
      schedule(
        id: quoteNotificationIdBase + slot,
        when: when,
        title: title,
        body: body,
        kind: NotificationKind.dailyQuote,
      );

  Future<void> cancelQuoteNotifications() => cancelIds([
        for (var slot = 0; slot < quoteNotificationSlots; slot++)
          quoteNotificationIdBase + slot,
      ]);
}
