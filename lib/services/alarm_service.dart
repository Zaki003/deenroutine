import 'dart:io';

import 'package:alarm/alarm.dart';

/// Prayer-alarm playback: the full adhan clip plays via the `alarm`
/// package's own foreground-service audio (Android) / background-audio-
/// session playback (iOS), instead of [NotificationService]'s
/// `AndroidNotificationDetails.sound` - which Android is free to cut short
/// after a second or two since that API is meant for brief alert tones, not
/// a ~25s clip (confirmed on-device).
///
/// Not wired up for habit reminders - those still go through
/// [NotificationService].
class AlarmService {
  /// How many times a prayer's alarm rings if left untouched, spaced
  /// [repeatInterval] apart. See `PrayerProvider.cancelActiveAlarms` for what
  /// stops it early - the plugin has no notion of "ignored vs. acknowledged",
  /// so a plain "this occurrence finished playing" doesn't cancel the rest.
  static const repeatCount = 5;
  static const repeatInterval = Duration(minutes: 2);

  static const _assetAudioPath = 'assets/sounds/adhan_takbir.mp3';

  Future<void> init() => Alarm.init();

  /// Schedules [repeatCount] occurrences of [baseId]'s alarm, [repeatInterval]
  /// apart starting at [firstRing], each playing the full clip once (not
  /// looped). A [firstRing] already in the past skips the whole series, same
  /// as the notification-based scheduling this replaces.
  Future<void> scheduleRepeatingAlarm({
    required int baseId,
    required String title,
    required String body,
    required DateTime firstRing,
    required String stopLabel,
  }) async {
    if (firstRing.isBefore(DateTime.now())) return;
    for (var i = 0; i < repeatCount; i++) {
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: _occurrenceId(baseId, i),
          dateTime: firstRing.add(repeatInterval * i),
          assetAudioPath: _assetAudioPath,
          loopAudio: false,
          vibrate: true,
          warningNotificationOnKill: Platform.isIOS,
          androidFullScreenIntent: true,
          volumeSettings: const VolumeSettings.fixed(volume: 0.8),
          notificationSettings: NotificationSettings(
            title: title,
            body: body,
            stopButton: stopLabel,
          ),
        ),
      );
    }
  }

  /// Stops every occurrence of [baseId]'s alarm. Safe to call unconditionally
  /// - stopping one that already rang, or was never scheduled, is a no-op.
  Future<void> cancelRepeatingAlarm(int baseId) async {
    for (var i = 0; i < repeatCount; i++) {
      await Alarm.stop(_occurrenceId(baseId, i));
    }
  }

  int _occurrenceId(int baseId, int i) => baseId * 10 - i;
}
