import 'package:cloud_firestore/cloud_firestore.dart';

/// One user's progress through one Learn topic. Doc id is `${uid}_${category}`
/// (same idempotent-upsert scheme as [HabitLog]'s `${habitId}_${y}-${m}-${d}`),
/// so every write is a merge-set with no existence check needed.
class LearnProgress {
  final String progressId;
  final String uid;
  final String category;

  /// Question ids walked through as a lesson so far. Kept as a set of ids
  /// rather than a count so resuming stays correct even if a category's
  /// question list changes later.
  final List<String> lessonQuestionIds;
  final bool lessonsDone;

  /// True once the scored assessment has been submitted at least once —
  /// this, together with [lessonsDone], is what gates the next topic.
  final bool assessmentDone;
  final int assessmentScore;
  final int assessmentTotal;

  LearnProgress({
    required this.progressId,
    required this.uid,
    required this.category,
    this.lessonQuestionIds = const [],
    this.lessonsDone = false,
    this.assessmentDone = false,
    this.assessmentScore = 0,
    this.assessmentTotal = 0,
  });

  bool get isTopicComplete => lessonsDone && assessmentDone;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'category': category,
        'lessonQuestionIds': lessonQuestionIds,
        'lessonsDone': lessonsDone,
        'assessmentDone': assessmentDone,
        'assessmentScore': assessmentScore,
        'assessmentTotal': assessmentTotal,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory LearnProgress.fromMap(String id, Map<String, dynamic> map) {
    return LearnProgress(
      progressId: id,
      uid: map['uid'] ?? '',
      category: map['category'] ?? '',
      lessonQuestionIds: map['lessonQuestionIds'] != null
          ? List<String>.from(map['lessonQuestionIds'] as List)
          : const [],
      lessonsDone: map['lessonsDone'] ?? false,
      assessmentDone: map['assessmentDone'] ?? false,
      assessmentScore: map['assessmentScore'] as int? ?? 0,
      assessmentTotal: map['assessmentTotal'] as int? ?? 0,
    );
  }
}
