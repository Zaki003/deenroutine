import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_result.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/star_pattern.dart';
import 'quiz_length_options.dart';
import 'quiz_screen.dart';

/// Quiz tab landing: personal-best banner, question-count picker, start.
class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  int _selectedCount = kQuizQuestionCountOptions[1];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.watch<AuthProvider>().firebaseUser?.uid;

    return ColoredBox(
      color: DeenColors.surface(dark),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            l10n.quizTabTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DeenColors.primaryText(dark),
            ),
          ),
          const SizedBox(height: 16),
          if (uid != null) _BestScoreBanner(uid: uid, dark: dark, l10n: l10n),
          const SizedBox(height: 20),
          Text(
            l10n.quizChooseLengthLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: DeenColors.primaryText(dark),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final count in kQuizQuestionCountOptions)
                _LengthChip(
                  count: count,
                  minutes: (count * 2 / 5).round(),
                  selected: count == _selectedCount,
                  dark: dark,
                  onTap: () => setState(() => _selectedCount = count),
                ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(questionCount: _selectedCount),
              ),
            ),
            child: Text(l10n.quizStartButton),
          ),
        ],
      ),
    );
  }
}

class _BestScoreBanner extends StatelessWidget {
  final String uid;
  final bool dark;
  final AppLocalizations l10n;

  const _BestScoreBanner({required this.uid, required this.dark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeenColors.panelBackground(dark),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          StarPattern(opacity: dark ? 0.07 : 0.09, color: DeenColors.gold),
          FutureBuilder<QuizResult?>(
            future: FirestoreService().getBestQuizResult(uid),
            builder: (context, snapshot) {
              final best = snapshot.data;
              return Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 22, color: DeenColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: (best == null || best.totalQuestions == 0)
                        ? Text(
                            l10n.quizNoAttemptsYet,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: DeenColors.primaryText(dark),
                            ),
                          )
                        : Text(
                            l10n.quizBestScore(
                              best.score,
                              best.totalQuestions,
                              (best.score / best.totalQuestions * 100).round(),
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: DeenColors.primaryText(dark),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LengthChip extends StatelessWidget {
  final int count;
  final int minutes;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _LengthChip({
    required this.count,
    required this.minutes,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? DeenColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? DeenColors.primary : DeenColors.outlineFaint(dark),
          ),
        ),
        child: Text(
          '$count · ${l10n.quizMinutesEstimate(minutes)}',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : DeenColors.textMuted,
          ),
        ),
      ),
    );
  }
}
