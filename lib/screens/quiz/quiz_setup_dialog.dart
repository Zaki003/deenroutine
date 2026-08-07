import 'package:flutter/material.dart';
import 'quiz_screen.dart';

const List<int> kQuizQuestionCountOptions = [5, 10, 15, 20];

/// Prompts the user for how many questions to practice (FR-10), then
/// opens the quiz. Call this from the quiz entry point (e.g. the
/// dashboard's quiz icon).
Future<void> startQuiz(BuildContext context) async {
  final count = await showDialog<int>(
    context: context,
    builder: (context) => const _QuizSetupDialog(),
  );
  if (count == null || !context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => QuizScreen(questionCount: count)),
  );
}

class _QuizSetupDialog extends StatelessWidget {
  const _QuizSetupDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_rounded, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'How many questions?',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how many questions you\'d like to practice.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final count in kQuizQuestionCountOptions)
                  _CountChoice(count: count, onTap: () => Navigator.pop(context, count)),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChoice extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CountChoice({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: Text(
              '$count',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
