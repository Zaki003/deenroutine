import 'package:cloud_firestore/cloud_firestore.dart';

class HabitLog {
  final String logId;
  final String habitId;
  final String uid;
  final DateTime date;
  final bool status;

  /// Numeric tracking: the count logged so far that day (e.g. 6 of 10 pages).
  final int? numericValue;
  /// Timer tracking: elapsed seconds logged so far that day.
  final int? timerElapsedSeconds;
  /// Checklist tracking: which of the habit's checklistItems (by exact
  /// text) were checked off that day.
  final List<String>? checklistDone;
  /// Rating tracking: the value picked that day, out of the habit's
  /// ratingScale.
  final int? ratingValue;

  HabitLog({
    required this.logId,
    required this.habitId,
    required this.uid,
    required this.date,
    required this.status,
    this.numericValue,
    this.timerElapsedSeconds,
    this.checklistDone,
    this.ratingValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'uid': uid,
      'date': Timestamp.fromDate(date),
      'status': status,
      'numericValue': numericValue,
      'timerElapsedSeconds': timerElapsedSeconds,
      'checklistDone': checklistDone,
      'ratingValue': ratingValue,
    };
  }

  factory HabitLog.fromMap(String id, Map<String, dynamic> map) {
    return HabitLog(
      logId: id,
      habitId: map['habitId'] ?? '',
      uid: map['uid'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? false,
      numericValue: map['numericValue'] as int?,
      timerElapsedSeconds: map['timerElapsedSeconds'] as int?,
      checklistDone: map['checklistDone'] != null
          ? List<String>.from(map['checklistDone'] as List)
          : null,
      ratingValue: map['ratingValue'] as int?,
    );
  }
}
