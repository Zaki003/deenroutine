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

  /// One line of reasoning shown after answering (e.g. citing the ayah or
  /// hadith behind the correct option). Optional and empty on most questions
  /// until content adds it — the quiz screen just skips showing anything
  /// when it's blank, same non-breaking approach as [questionTextBn].
  final String explanation;
  final String explanationBn;

  QuizQuestion({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.questionTextBn = '',
    this.optionsBn = const [],
    this.explanation = '',
    this.explanationBn = '',
  });

  String displayQuestionText(bool bangla) =>
      (bangla && questionTextBn.isNotEmpty) ? questionTextBn : questionText;

  List<String> displayOptions(bool bangla) =>
      (bangla && optionsBn.length == options.length) ? optionsBn : options;

  String displayExplanation(bool bangla) =>
      (bangla && explanationBn.isNotEmpty) ? explanationBn : explanation;

  factory QuizQuestion.fromMap(String id, Map<String, dynamic> map) {
    return QuizQuestion(
      questionId: id,
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      questionTextBn: map['questionTextBn'] ?? '',
      optionsBn: List<String>.from(map['optionsBn'] ?? []),
      explanation: map['explanation'] ?? '',
      explanationBn: map['explanationBn'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'questionText': questionText,
        'options': options,
        'correctAnswer': correctAnswer,
        'questionTextBn': questionTextBn,
        'optionsBn': optionsBn,
        'explanation': explanation,
        'explanationBn': explanationBn,
      };
}
