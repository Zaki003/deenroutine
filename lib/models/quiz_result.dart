import 'package:cloud_firestore/cloud_firestore.dart';

class QuizResult {
  final String resultId;
  final String uid;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  QuizResult({
    required this.resultId,
    required this.uid,
    required this.score,
    required this.totalQuestions,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'score': score,
        'totalQuestions': totalQuestions,
        'completedAt': Timestamp.fromDate(completedAt),
      };

  factory QuizResult.fromMap(String id, Map<String, dynamic> map) => QuizResult(
        resultId: id,
        uid: map['uid'] ?? '',
        score: map['score'] ?? 0,
        totalQuestions: map['totalQuestions'] ?? 0,
        completedAt: (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
