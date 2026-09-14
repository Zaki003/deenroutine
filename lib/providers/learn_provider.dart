import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/learn_progress.dart';
import '../models/quiz_question.dart';
import '../services/firestore_service.dart';

/// Kinds of error [LearnProvider] can surface. Kept as a type rather than a
/// pre-formatted English sentence so the UI layer can localize the message
/// (providers stay `AppLocalizations`/`BuildContext`-free).
enum LearnErrorType { syncFailed, saveFailed }

/// Topic-path state for the Learn tab: fixed unlock order, per-topic
/// progress, and the lesson/assessment write-through methods. Kept separate
/// from [HabitProvider] - different collection, screen, and lifecycle, the
/// same split Prayer already keeps from Habit.
class LearnProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  /// Fixed unlock sequence: foundations first (Belief, Pillars - also the
  /// two smallest topics, for fast early wins), then the most daily-relevant
  /// pillar (Salah) and the primary source (Quran), then the narrative arc
  /// Seerah -> Prophets -> History, then two practice deep-dives (Ramadan,
  /// Hajj), with Manners closing it out.
  static const List<String> kTopicOrder = [
    'Belief', 'Pillars', 'Salah', 'Quran', 'Seerah',
    'Prophets', 'History', 'Ramadan', 'Hajj', 'Manners',
  ];

  StreamSubscription<List<LearnProgress>>? _progressSub;
  String? _listeningUid;

  Map<String, LearnProgress> _progressByCategory = {};

  /// False until [listenToProgress]'s stream delivers its first snapshot (or
  /// error) - lets the trail map tell "still loading" apart from "genuinely
  /// no progress yet".
  bool _hasLoadedOnce = false;
  bool get hasLoadedOnce => _hasLoadedOnce;

  LearnErrorType? _errorType;
  String? _errorDetail;
  LearnErrorType? get errorType => _errorType;
  String? get errorDetail => _errorDetail;
  bool get hasError => _errorType != null;

  void clearError() {
    _errorType = null;
    _errorDetail = null;
    notifyListeners();
  }

  void _setError(LearnErrorType type, String detail) {
    _errorType = type;
    _errorDetail = detail;
    notifyListeners();
  }

  void listenToProgress(String uid) {
    // Avoid stacking duplicate listeners if this is called more than once
    // for the same user (e.g. LearnHomeScreen rebuilding).
    if (_listeningUid == uid && _progressSub != null) return;

    _progressSub?.cancel();
    _listeningUid = uid;

    _progressSub = _service.watchLearnProgress(uid).listen(
      (progress) {
        _progressByCategory = {for (final p in progress) p.category: p};
        _errorType = null;
        _errorDetail = null;
        _hasLoadedOnce = true;
        notifyListeners();
      },
      onError: (Object e) {
        _hasLoadedOnce = true;
        _setError(LearnErrorType.syncFailed, e.toString());

        _progressSub?.cancel();
        _progressSub = null;
        Future.delayed(const Duration(seconds: 3), () {
          if (_listeningUid == uid) {
            _listeningUid = null; // force re-subscribe
            listenToProgress(uid);
          }
        });
      },
    );
  }

  /// Cancels the progress listener and clears its state - call this from
  /// [LearnHomeScreen]'s `dispose()`, mirroring [HabitProvider.stopListening].
  void stopListening() {
    _progressSub?.cancel();
    _progressSub = null;
    _listeningUid = null;
    _progressByCategory = {};
    _errorType = null;
    _errorDetail = null;
    _hasLoadedOnce = false;
    // Deferred: notifying synchronously from a caller's dispose() (widget
    // tree locked mid-teardown) throws "setState() called when widget tree
    // was locked" - a microtask runs once that lock lifts.
    Future.microtask(notifyListeners);
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  LearnProgress? progressFor(String category) => _progressByCategory[category];

  bool isTopicComplete(String category) => progressFor(category)?.isTopicComplete ?? false;

  /// [kTopicOrder]'s first topic is always unlocked; every other topic
  /// unlocks once every topic before it in the sequence is complete.
  bool isUnlocked(String category) {
    final index = kTopicOrder.indexOf(category);
    if (index <= 0) return true;
    return kTopicOrder.take(index).every(isTopicComplete);
  }

  int lessonsCompletedCount(String category) =>
      progressFor(category)?.lessonQuestionIds.length ?? 0;

  /// The first unlocked-but-incomplete topic, or null once every topic in
  /// [kTopicOrder] is done.
  String? get activeTopic {
    for (final category in kTopicOrder) {
      if (!isTopicComplete(category)) return category;
    }
    return null;
  }

  Future<List<QuizQuestion>> loadLessonQuestions(String category) {
    return _service.getLessonQuestions(category);
  }

  Future<void> completeLessonQuestion(
    String uid,
    String category,
    String questionId, {
    required bool isLastQuestion,
  }) async {
    try {
      await _service.logLessonQuestion(uid, category, questionId, lessonsDone: isLastQuestion);
    } catch (e) {
      _setError(LearnErrorType.saveFailed, e.toString());
    }
  }

  Future<void> completeAssessment(
    String uid,
    String category, {
    required int score,
    required int total,
  }) async {
    try {
      await _service.saveAssessmentResult(uid, category, score: score, total: total);
    } catch (e) {
      _setError(LearnErrorType.saveFailed, e.toString());
    }
  }
}
