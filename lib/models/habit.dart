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

  /// Calendar day [completed] was last set on. A habit only reads as done
  /// for "today" when this matches today's date — otherwise the completed
  /// flag is a leftover from a previous day and the habit is due again.
  final DateTime? lastCompletedDate;
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
    this.lastCompletedDate,
    this.selectedDays = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Whether [completed] reflects today, rather than a stale value carried
  /// over from a previous day the habit was checked off.
  bool get isCompletedToday {
    if (!completed || lastCompletedDate == null) return false;
    final now = DateTime.now();
    final d = lastCompletedDate!;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'category': category.name,
      'frequency': frequency.name,
      'completed': completed,
      'lastCompletedDate':
          lastCompletedDate != null ? Timestamp.fromDate(lastCompletedDate!) : null,
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
      lastCompletedDate: (map['lastCompletedDate'] as Timestamp?)?.toDate(),
      selectedDays: List<int>.from(map['selectedDays'] ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Habit copyWith({bool? completed, DateTime? lastCompletedDate}) {
    return Habit(
      habitId: habitId,
      uid: uid,
      title: title,
      category: category,
      frequency: frequency,
      completed: completed ?? this.completed,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
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