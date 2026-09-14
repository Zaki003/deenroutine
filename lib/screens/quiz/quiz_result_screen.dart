import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/learn_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/learn_topic_labels.dart';
import 'quiz_screen.dart';

/// Shown after finishing a topic's assessment (FR-10). Score is feedback,
/// not a gate - the assessment always marks the topic's [category] complete
/// once submitted, regardless of score, so the next topic in
/// [LearnProvider.kTopicOrder] unlocks either way.
class QuizResultScreen extends StatelessWidget {
  final String category;
  final int score;
  final int total;
  final List<bool> answerResults;

  const QuizResultScreen({
    super.key,
    required this.category,
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
    final dark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final outcome = _outcome(theme.colorScheme, l10n);
    // watch, not read: the assessment's completeAssessment() write lands via
    // Firestore's round-trip through LearnProvider's listener, not
    // synchronously on navigation here - watching lets the unlocked banner
    // below pop in the moment that snapshot arrives rather than needing a
    // rebuild trigger of its own.
    final learnProvider = context.watch<LearnProvider>();
    final topicComplete = learnProvider.isTopicComplete(category);
    final topicIndex = LearnProvider.kTopicOrder.indexOf(category);
    final isLastTopic = topicIndex == LearnProvider.kTopicOrder.length - 1;

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
                    if (topicComplete) ...[
                      const SizedBox(height: 16),
                      _NextTopicBanner(
                        dark: dark,
                        message: isLastTopic
                            ? l10n.learnAllTopicsCompleteMessage
                            : l10n.learnNextTopicUnlockedMessage(
                                learnTopicLabel(
                                    l10n, LearnProvider.kTopicOrder[topicIndex + 1])),
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
                          builder: (_) => QuizScreen(category: category),
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

/// "{Topic} is now unlocked" / "You've completed every topic!" card.
/// Deliberately a plain static card rather than reusing the habit
/// milestone banner's flame animation - that's a streak-specific visual
/// identity, and this moment doesn't need to borrow it.
class _NextTopicBanner extends StatelessWidget {
  final bool dark;
  final String message;

  const _NextTopicBanner({required this.dark, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DeenColors.panelBackground(dark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_open_rounded, size: 20, color: DeenColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DeenColors.primaryText(dark),
              ),
            ),
          ),
        ],
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
