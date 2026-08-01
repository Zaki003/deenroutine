import 'package:cloud_firestore/cloud_firestore.dart';

enum HabitCategory { islam, lifestyle, learn, work }

enum HabitFrequency { daily, weekly, specificDays }

class Habit {
  final String habitId;
  final String uid;
  final String title;
  final HabitCategory category;
  final HabitFrequency frequency;
  final bool completed;
  final DateTime createdAt;

  /// Only meaningful when [frequency] is [HabitFrequency.specificDays].
  /// Indices follow the S M T W T F S order shown in the UI:
  /// 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat.
  final List<int> selectedDays;

  Habit({
    required this.habitId,
    required this.uid,
    required this.title,
    required this.category,
    required this.frequency,
    this.completed = false,
    this.selectedDays = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'category': category.name,
      'frequency': frequency.name,
      'completed': completed,
      'selectedDays': selectedDays,
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
      selectedDays: List<int>.from(map['selectedDays'] ?? const []),
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
      selectedDays: selectedDays,
      createdAt: createdAt,
    );
  }
}

/// Shared day-of-week labels/order used by the add-habit day picker and
/// habit card subtitle: S M T W T F S starting on Sunday.
const List<String> kWeekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const List<String> kWeekdayShortNames = [
  'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
];