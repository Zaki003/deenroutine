import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_result.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import 'quiz_screen.dart';

/// Beautified results page shown after finishing a quiz (FR-10).
class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final List<bool> answerResults;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    this.answerResults = const [],
  });

  double get _percentage => total == 0 ? 0 : score / total;

  ({IconData icon, Color color, String title, String message}) _outcome(
    ColorScheme scheme,
    AppLocalizations l10n,
  ) {
    final pct = _percentage;
    if (pct >= 0.8) {
      return (
        icon: Icons.emoji_events_rounded,
        color: scheme.accentAmber,
        title: l10n.quizOutcomeExcellentTitle,
        message: l10n.quizOutcomeExcellentMessage,
      );
    } else if (pct >= 0.5) {
      return (
        icon: Icons.thumb_up_rounded,
        color: scheme.success,
        title: l10n.quizOutcomeWellDoneTitle,
        message: l10n.quizOutcomeWellDoneMessage,
      );
    }
    return (
      icon: Icons.menu_book_rounded,
      color: scheme.accentBrown,
      title: l10n.quizOutcomeKeepLearningTitle,
      message: l10n.quizOutcomeKeepLearningMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final outcome = _outcome(theme.colorScheme, l10n);
    final uid = context.read<AuthProvider>().firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quizResultsAppBarTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: outcome.color.withValues(alpha: 0.15),
                        ),
                        child:
                            Icon(outcome.icon, size: 72, color: outcome.color),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      outcome.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: outcome.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      outcome.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _percentage),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 12,
                                strokeCap: StrokeCap.round,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    outcome.color),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(value * 100).round()}%',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  l10n.quizScoreOfTotal(score, total),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (answerResults.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < answerResults.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _StaggerIn(
                                index: i,
                                child: _QuestionResultRow(
                                    index: i, correct: answerResults[i]),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (uid != null) ...[
                      const SizedBox(height: 16),
                      FutureBuilder<QuizResult?>(
                        future: FirestoreService().getBestQuizResult(uid, total),
                        builder: (context, snapshot) {
                          final best = snapshot.data;
                          if (best == null || best.totalQuestions == 0) {
                            return Text(
                              l10n.quizNoAttemptsYet(total),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                          final bestPct =
                              (best.score / best.totalQuestions * 100).round();
                          return Text(
                            l10n.quizBestScore(
                                best.score, best.totalQuestions, bestPct),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.quizTryAgain),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(questionCount: total),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.home_rounded),
                      label: Text(l10n.quizBackToHome),
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the per-question breakdown: correct/wrong mark + question
/// number. Wrapped in [_StaggerIn] by the caller for the staggered reveal.
class _QuestionResultRow extends StatelessWidget {
  final int index;
  final bool correct;

  const _QuestionResultRow({required this.index, required this.correct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = correct ? theme.colorScheme.success : theme.colorScheme.error;
    final background = correct
        ? theme.colorScheme.successContainer
        : theme.colorScheme.errorSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            l10n.quizResultQuestionLabel(index + 1),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Delays [child]'s entrance by `index`-scaled steps so a list of rows
/// reveals one after another instead of all popping in at once.
class _StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggerIn({required this.index, required this.child});

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn> {
  bool _visible = false;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (MediaQuery.of(context).disableAnimations) {
      _visible = true;
      return;
    }
    Future.delayed(Duration(milliseconds: 550 + widget.index * 90), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0.06, 0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
