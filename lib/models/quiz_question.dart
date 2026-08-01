class QuizQuestion {
  final String questionId;
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromMap(String id, Map<String, dynamic> map) {
    return QuizQuestion(
      questionId: id,
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'questionText': questionText,
        'options': options,
        'correctAnswer': correctAnswer,
      };
}
