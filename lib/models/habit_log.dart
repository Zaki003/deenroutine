import 'package:cloud_firestore/cloud_firestore.dart';

class HabitLog {
  final String logId;
  final String habitId;
  final DateTime date;
  final bool status;

  HabitLog({
    required this.logId,
    required this.habitId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'date': Timestamp.fromDate(date),
      'status': status,
    };
  }

  factory HabitLog.fromMap(String id, Map<String, dynamic> map) {
    return HabitLog(
      logId: id,
      habitId: map['habitId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? false,
    );
  }
}
