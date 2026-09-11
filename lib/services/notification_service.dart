import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

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
    tz.setLocalLocation(tz.getLocation(deviceTimezone));

    const androidSettings =
        AndroidInitializationSettings('ic_notification');
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

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'deenroutine_reminders',
          'DeenRoutine Reminders',
          channelDescription: 'Habit and prayer time reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(int id) => _plugin.cancel(id: id);

  /// Schedules a one-off adhan notification for [time]. Unlike
  /// [scheduleDailyReminder], this doesn't use `matchDateTimeComponents` to
  /// recur daily at a fixed clock time - prayer times shift by a minute or
  /// two most days, so each day's actual time is scheduled fresh by
  /// [PrayerProvider] whenever it fetches new timings, rather than locked to
  /// today's clock time forever. A [time] already in the past (e.g. toggled
  /// on after that prayer has already passed today) is silently skipped;
  /// the next fetch that's still in the future will schedule normally.
  ///
  /// Uses its own channel (separate from 'deenroutine_reminders') because
  /// Android only lets a channel's sound be set once, at creation - this is
  /// the one place in the app the takbir clip should ever play, and users
  /// can mute it independently of habit reminders via system settings.
  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    final scheduled = tz.TZDateTime.from(time, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'deenroutine_adhan',
          'Adhan',
          channelDescription: 'Notification with adhan sound at each enabled prayer time',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('adhan_takbir'),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(sound: 'adhan_takbir.mp3'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}