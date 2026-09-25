import 'package:cloud_firestore/cloud_firestore.dart';

/// How a prayer was logged. Stored by [name], so renaming a value would
/// orphan every existing record - add new values, never rename these.
enum PrayerStatus {
  /// Prayed inside its own waqt.
  onTime,

  /// Prayed after the preferred part of the waqt but before the next salah
  /// starts - only Asr's last 20 minutes and Isha after midnight, see
  /// [PrayerWaqtWindow.hasLateWindow].
  late,

  /// Made up after the next salah had started (or, for Fajr, after sunrise).
  qada,

  /// Deliberately marked as not prayed. An unlogged prayer is simply absent
  /// from the record, never stored as this.
  missed,

  /// Not due - during a period, when prayer isn't required. Neither prayed
  /// nor missed: it's left out of every percentage and pauses a streak
  /// without breaking it. Never labelled with a reason anywhere in the UI.
  excused;

  /// Whether this counts as having prayed (qada included).
  bool get counted => this == onTime || this == late || this == qada;

  static PrayerStatus? fromName(Object? name) {
    for (final s in PrayerStatus.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// One user's five prayers for one prayer day. A prayer day runs from Fajr
/// to the next Fajr, not midnight to midnight, so Isha prayed at 12:30 AM
/// lands on the previous date's record - see [currentPrayerDay].
///
/// Keyed on the canonical English prayer names ('Fajr', ...) rather than
/// display text, so switching the app language never loses a match.
class PrayerLog {
  final String uid;

  /// `yyyy-MM-dd` of the prayer day. A string rather than a Timestamp so an
  /// equality query can't miss on a timezone-shifted midnight.
  final String day;
  final Map<String, PrayerStatus> statuses;

  const PrayerLog({required this.uid, required this.day, required this.statuses});

  static const prayerKeys = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  /// Firestore field for a prayer key - lowercase so the document reads
  /// naturally in the console ('fajr': 'onTime').
  static String fieldFor(String prayerKey) => prayerKey.toLowerCase();

  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// The inverse of [dayKey]: local midnight of that date.
  static DateTime parseDayKey(String key) {
    final p = key.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  PrayerStatus? statusFor(String prayerKey) => statuses[prayerKey];

  int get prayedCount => statuses.values.where((s) => s.counted).length;

  factory PrayerLog.fromMap(Map<String, dynamic> map) {
    return PrayerLog(
      uid: map['uid'] ?? '',
      day: map['day'] ?? '',
      statuses: {
        for (final key in prayerKeys)
          if (PrayerStatus.fromName(map[fieldFor(key)]) case final status?) key: status,
      },
    );
  }

  static Map<String, dynamic> baseFields(String uid, DateTime day) => {
        'uid': uid,
        'day': dayKey(day),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
