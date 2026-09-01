import 'package:firebase_analytics/firebase_analytics.dart';

/// Product-usage analytics, entirely opt-in (see [AnalyticsProvider]). Every
/// event here is deliberately structural — a category, a tracking type, a
/// day count, a score band — never a habit title, quiz answer, or anything
/// else the user typed.
///
/// [FirebaseAnalytics.setAnalyticsCollectionEnabled] is the single gate:
/// once set false, the SDK drops events at the call site rather than queuing
/// them, so every method here can be called unconditionally without each
/// call site needing to check whether the user has opted in.
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> setEnabled(bool enabled) {
    return _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logHabitCreated({
    required String category,
    required String trackingType,
    String? templateId,
  }) {
    return _analytics.logEvent(
      name: 'habit_created',
      parameters: {
        'category': category,
        'tracking_type': trackingType,
        if (templateId != null) 'template_id': templateId,
      },
    );
  }

  Future<void> logHabitCompleted({required String trackingType}) {
    return _analytics.logEvent(
      name: 'habit_completed',
      parameters: {'tracking_type': trackingType},
    );
  }

  Future<void> logQuizCompleted({required int totalQuestions, required int scorePercent}) {
    return _analytics.logEvent(
      name: 'quiz_completed',
      parameters: {
        'total_questions': totalQuestions,
        'score_band': _scoreBand(scorePercent),
      },
    );
  }

  Future<void> logStreakMilestone({required int days}) {
    return _analytics.logEvent(
      name: 'streak_milestone_reached',
      parameters: {'days': days},
    );
  }

  String _scoreBand(int scorePercent) {
    if (scorePercent <= 25) return '0-25';
    if (scorePercent <= 50) return '26-50';
    if (scorePercent <= 75) return '51-75';
    return '76-100';
  }
}
