import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/firestore_service.dart';

class HabitProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  final _uuid = const Uuid();

  StreamSubscription<List<Habit>>? _habitsSub;
  String? _listeningUid;

  List<Habit> _habits = [];
  List<Habit> get habits => _habits;

  String? _error;
  String? get error => _error;
  void clearError() {
    _error = null;
    notifyListeners();
  }

  double get completionPercentage {
    if (_habits.isEmpty) return 0;
    final done = _habits.where((h) => h.completed).length;
    return done / _habits.length;
  }

  void listenToHabits(String uid) {
    // Avoid stacking duplicate listeners if this is called more than once
    // for the same user (e.g. DashboardScreen rebuilding).
    if (_listeningUid == uid && _habitsSub != null) return;

    _habitsSub?.cancel();
    _listeningUid = uid;

    _habitsSub = _service.watchHabits(uid).listen(
      (habits) {
        _habits = habits;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        // This is the fix for "works once, then needs a restart": previously
        // an error here (e.g. a missing Firestore composite index, or a
        // permission rule rejecting the *listener* specifically) silently
        // killed the subscription with no feedback. Now it's surfaced, and
        // we retry so a transient error (e.g. brief connectivity loss)
        // recovers on its own instead of requiring an app restart.
        _error = 'Habit sync error: $e';
        notifyListeners();

        _habitsSub?.cancel();
        _habitsSub = null;
        Future.delayed(const Duration(seconds: 3), () {
          if (_listeningUid == uid) {
            _listeningUid = null; // force re-subscribe
            listenToHabits(uid);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _habitsSub?.cancel();
    super.dispose();
  }

  Future<void> addHabit({
    required String uid,
    required String title,
    required HabitCategory category,
    required HabitFrequency frequency,
    List<int> selectedDays = const [],
  }) {
    final habit = Habit(
      habitId: _uuid.v4(),
      uid: uid,
      title: title,
      category: category,
      frequency: frequency,
      selectedDays: selectedDays,
    );
    return _service.addHabit(habit);
  }

  Future<void> toggleComplete(Habit habit) async {
    try {
      await _service.markHabitComplete(habit, !habit.completed);
    } catch (e) {
      _error = 'Could not update habit: $e';
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _service.deleteHabit(habitId);
    } catch (e) {
      _error = 'Could not delete habit: $e';
      notifyListeners();
    }
  }

  Future<int> streakFor(String habitId) async {
    final logs = await _service.watchHabitLogs(habitId).first;
    return _service.calculateStreak(logs);
  }
}