import 'package:cloud_firestore/cloud_firestore.dart';

class QuizResult {
  final String resultId;
  final String uid;
  final int score;
  final DateTime completedAt;

  QuizResult({
    required this.resultId,
    required this.uid,
    required this.score,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'score': score,
        'completedAt': Timestamp.fromDate(completedAt),
      };

  factory QuizResult.fromMap(String id, Map<String, dynamic> map) => QuizResult(
        resultId: id,
        uid: map['uid'] ?? '',
        score: map['score'] ?? 0,
        completedAt: (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
