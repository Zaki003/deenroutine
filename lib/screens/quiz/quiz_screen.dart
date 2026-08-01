import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_result.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _service = FirestoreService();
  late Future<List<QuizQuestion>> _questionsFuture;
  int _index = 0;
  int _score = 0;
  String? _selectedOption;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _service.getQuizQuestions();
  }

  Future<void> _submitResult(List<QuizQuestion> questions) async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final result = QuizResult(
      resultId: const Uuid().v4(),
      uid: uid,
      score: _score,
    );
    await _service.saveQuizResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Islamic Knowledge Quiz')),
      body: FutureBuilder<List<QuizQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snapshot.data!;
          if (questions.isEmpty) {
            return const Center(child: Text('No quiz questions available yet.'));
          }

          if (_finished) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Quiz complete!', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text('Score: $_score / ${questions.length}'),
                ],
              ),
            );
          }

          final q = questions[_index];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Question ${_index + 1} of ${questions.length}'),
                const SizedBox(height: 12),
                Text(q.questionText, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                for (final option in q.options)
                  RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: _selectedOption,
                    onChanged: (v) => setState(() => _selectedOption = v),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _selectedOption == null
                      ? null
                      : () async {
                          if (_selectedOption == q.correctAnswer) _score++;
                          if (_index < questions.length - 1) {
                            setState(() {
                              _index++;
                              _selectedOption = null;
                            });
                          } else {
                            await _submitResult(questions);
                            setState(() => _finished = true);
                          }
                        },
                  child: Text(_index < questions.length - 1 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
