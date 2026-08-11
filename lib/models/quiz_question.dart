class QuizQuestion {
  final String questionId;
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  /// Bangla translations of [questionText]/[options], empty until Bangla
  /// content is added to the `QuizQuestions` collection. Answer matching
  /// always uses the canonical English [options]/[correctAnswer] — these
  /// are display-only, and [displayOptions] falls back to [options] when
  /// missing or mismatched in length.
  final String questionTextBn;
  final List<String> optionsBn;

  QuizQuestion({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.questionTextBn = '',
    this.optionsBn = const [],
  });

  String displayQuestionText(bool bangla) =>
      (bangla && questionTextBn.isNotEmpty) ? questionTextBn : questionText;

  List<String> displayOptions(bool bangla) =>
      (bangla && optionsBn.length == options.length) ? optionsBn : options;

  factory QuizQuestion.fromMap(String id, Map<String, dynamic> map) {
    return QuizQuestion(
      questionId: id,
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      questionTextBn: map['questionTextBn'] ?? '',
      optionsBn: List<String>.from(map['optionsBn'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'questionText': questionText,
        'options': options,
        'correctAnswer': correctAnswer,
        'questionTextBn': questionTextBn,
        'optionsBn': optionsBn,
      };
}
