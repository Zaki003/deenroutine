import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final int questionCount;

  const QuizScreen({super.key, required this.questionCount});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _service = FirestoreService();
  late Future<List<QuizQuestion>> _questionsFuture;
  int _index = 0;
  int _score = 0;
  String? _selectedOption;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _service.getQuizQuestions(count: widget.questionCount);
  }

  Future<void> _submitResult(List<QuizQuestion> questions) async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final result = QuizResult(
      resultId: const Uuid().v4(),
      uid: uid,
      score: _score,
      totalQuestions: questions.length,
    );
    await _service.saveQuizResult(result);
  }

  void _selectOption(String option) {
    if (_answered) return;
    setState(() => _selectedOption = option);
  }

  void _checkAnswer(QuizQuestion q) {
    setState(() {
      _answered = true;
      if (_selectedOption == q.correctAnswer) _score++;
    });
  }

  Future<void> _next(List<QuizQuestion> questions) async {
    if (_index < questions.length - 1) {
      setState(() {
        _index++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      await _submitResult(questions);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(score: _score, total: questions.length),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isBangla = context.watch<LocaleProvider>().isBangla;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quizAppBarTitle)),
      body: FutureBuilder<List<QuizQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snapshot.data!;
          if (questions.isEmpty) {
            return Center(child: Text(l10n.quizNoQuestions));
          }

          final q = questions[_index];
          final options = q.options;
          final displayOptions = q.displayOptions(isBangla);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / questions.length,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.quizQuestionProgress(_index + 1, questions.length),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    q.displayQuestionText(isBangla),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < options.length; i++)
                        _OptionTile(
                          option: displayOptions[i],
                          isSelected: _selectedOption == options[i],
                          isCorrectAnswer: options[i] == q.correctAnswer,
                          answered: _answered,
                          onTap: () => _selectOption(options[i]),
                        ),
                    ],
                  ),
                ),
                if (_answered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          _selectedOption == q.correctAnswer
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _selectedOption == q.correctAnswer
                              ? theme.colorScheme.success
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedOption == q.correctAnswer
                                ? l10n.quizCorrect
                                : l10n.quizCorrectAnswer(
                                    displayOptions[options.indexOf(q.correctAnswer)]),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                FilledButton(
                  onPressed: !_answered
                      ? (_selectedOption == null ? null : () => _checkAnswer(q))
                      : () => _next(questions),
                  child: Text(
                    !_answered
                        ? l10n.quizCheckAnswer
                        : (_index < questions.length - 1
                            ? l10n.quizNextQuestion
                            : l10n.quizSeeResults),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool isCorrectAnswer;
  final bool answered;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.isCorrectAnswer,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color background = theme.colorScheme.secondaryContainer;
    Color foreground = theme.colorScheme.onSecondaryContainer;
    Color borderColor = Colors.transparent;
    IconData? trailingIcon;

    if (answered) {
      if (isCorrectAnswer) {
        background = theme.colorScheme.successContainer;
        foreground = theme.colorScheme.onSuccessContainer;
        borderColor = theme.colorScheme.success;
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected) {
        background = theme.colorScheme.errorSurface;
        foreground = theme.colorScheme.onErrorContainer;
        borderColor = theme.colorScheme.error;
        trailingIcon = Icons.cancel_rounded;
      } else {
        background = theme.colorScheme.surfaceContainerHighest;
        foreground = theme.colorScheme.onSurfaceVariant;
      }
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      background = theme.colorScheme.primary.withValues(alpha: 0.15);
      foreground = theme.colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: answered ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: isSelected || (answered && isCorrectAnswer)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  Icon(
                    trailingIcon,
                    color: isCorrectAnswer
                        ? theme.colorScheme.success
                        : theme.colorScheme.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
