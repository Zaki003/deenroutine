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

  const QuizResultScreen({super.key, required this.score, required this.total});

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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                  child: Icon(outcome.icon, size: 72, color: outcome.color),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                outcome.title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: outcome.color),
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
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(outcome.color),
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
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (uid != null) ...[
                const SizedBox(height: 16),
                FutureBuilder<QuizResult?>(
                  future: FirestoreService().getBestQuizResult(uid),
                  builder: (context, snapshot) {
                    final best = snapshot.data;
                    if (best == null || best.totalQuestions == 0) {
                      return const SizedBox.shrink();
                    }
                    final bestPct = (best.score / best.totalQuestions * 100).round();
                    return Text(
                      l10n.quizBestScore(best.score, best.totalQuestions, bestPct),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 40),
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
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
