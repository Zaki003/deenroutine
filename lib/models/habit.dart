import 'package:cloud_firestore/cloud_firestore.dart';

enum HabitCategory { islam, lifestyle, learn, work }

enum HabitFrequency { daily, weekly, specificDates }

class Habit {
  final String habitId;
  final String uid;
  final String title;
  final HabitCategory category;
  final HabitFrequency frequency;
  final bool completed;
  final DateTime createdAt;

  Habit({
    required this.habitId,
    required this.uid,
    required this.title,
    required this.category,
    required this.frequency,
    this.completed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'category': category.name,
      'frequency': frequency.name,
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Habit.fromMap(String id, Map<String, dynamic> map) {
    return Habit(
      habitId: id,
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      category: HabitCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => HabitCategory.lifestyle,
      ),
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      completed: map['completed'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Habit copyWith({bool? completed}) {
    return Habit(
      habitId: habitId,
      uid: uid,
      title: title,
      category: category,
      frequency: frequency,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }
}
