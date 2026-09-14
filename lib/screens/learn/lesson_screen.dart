import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learn_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/learn_topic_labels.dart';
import '../../widgets/quiz_option_tile.dart';
import 'path_complete_screen.dart';

/// Untimed walkthrough of every not-yet-seen question in [category], in
/// fixed lesson order - no score, no timer, same select/check/reveal
/// interaction as the assessment via [QuizOptionTile]. Redirects straight to
/// [PathCompleteScreen] if there's nothing left to walk through, which is
/// what lets revisiting an already-finished topic "just work" with no
/// separate branching in LearnHomeScreen.
class LessonScreen extends StatefulWidget {
  final String category;

  const LessonScreen({super.key, required this.category});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final Future<void> _loadFuture;
  List<QuizQuestion> _allQuestions = [];
  List<QuizQuestion> _remaining = [];
  int _index = 0;
  String? _selectedOption;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final provider = context.read<LearnProvider>();
    final all = await provider.loadLessonQuestions(widget.category);
    final done = provider.progressFor(widget.category)?.lessonQuestionIds.toSet() ?? <String>{};
    _allQuestions = all;
    _remaining = all.where((q) => !done.contains(q.questionId)).toList();
  }

  void _selectOption(String option) {
    if (_answered) return;
    setState(() => _selectedOption = option);
  }

  Future<void> _checkAnswer(QuizQuestion q) async {
    setState(() => _answered = true);
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    await context.read<LearnProvider>().completeLessonQuestion(
          uid,
          widget.category,
          q.questionId,
          isLastQuestion: _index == _remaining.length - 1,
        );
  }

  void _next() {
    if (_index < _remaining.length - 1) {
      setState(() {
        _index++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PathCompleteScreen(
            category: widget.category,
            lessonCount: _allQuestions.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isBangla = context.watch<LocaleProvider>().isBangla;

    return Scaffold(
      appBar: AppBar(title: Text(learnTopicLabel(l10n, widget.category))),
      backgroundColor: DeenColors.surface(dark),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: DeenColors.gold));
          }
          if (_remaining.isEmpty) {
            // Nothing left to walk through - redirect once this frame
            // finishes building rather than mid-build.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PathCompleteScreen(
                    category: widget.category,
                    lessonCount: _allQuestions.length,
                  ),
                ),
              );
            });
            return const SizedBox.shrink();
          }

          final q = _remaining[_index];
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
                    value: (_index + 1) / _remaining.length,
                    minHeight: 8,
                    backgroundColor: DeenColors.trackLine(dark),
                    valueColor: AlwaysStoppedAnimation(DeenColors.gold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.quizQuestionProgress(_index + 1, _remaining.length),
                  style: TextStyle(fontSize: 12.5, color: DeenColors.textMuted(dark)),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DeenColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    q.displayQuestionText(isBangla),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: DeenColors.paper,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < options.length; i++)
                        QuizOptionTile(
                          option: displayOptions[i],
                          isSelected: _selectedOption == options[i],
                          isCorrectAnswer: options[i] == q.correctAnswer,
                          answered: _answered,
                          onTap: () => _selectOption(options[i]),
                        ),
                    ],
                  ),
                ),
                if (_answered) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          _selectedOption == q.correctAnswer
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _selectedOption == q.correctAnswer
                              ? DeenColors.green
                              : DeenColors.rust,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedOption == q.correctAnswer
                                ? l10n.quizCorrect
                                : l10n.quizCorrectAnswer(
                                    displayOptions[options.indexOf(q.correctAnswer)]),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: DeenColors.primaryText(dark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (q.displayExplanation(isBangla).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        q.displayExplanation(isBangla),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: DeenColors.textMuted(dark),
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
                FilledButton(
                  onPressed: !_answered
                      ? (_selectedOption == null ? null : () => _checkAnswer(q))
                      : _next,
                  child: Text(
                    !_answered
                        ? l10n.quizCheckAnswer
                        : (_index < _remaining.length - 1
                            ? l10n.quizNextQuestion
                            : l10n.learnLessonFinishButton),
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
