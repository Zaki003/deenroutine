import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/deen_colors.dart';
import '../../utils/learn_topic_labels.dart';
import '../quiz/quiz_screen.dart';

/// Shown once every lesson in [category] has been walked through. The
/// assessment is the default next action but skippable - skipping leaves
/// the topic in-progress (lessons done, assessment not) and the next topic
/// locked, no other penalty.
class PathCompleteScreen extends StatelessWidget {
  final String category;
  final int lessonCount;

  const PathCompleteScreen({super.key, required this.category, required this.lessonCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final topicName = learnTopicLabel(l10n, category);

    return Scaffold(
      backgroundColor: DeenColors.surface(dark),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(scale: value, child: child),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DeenColors.gold.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, size: 72, color: DeenColors.gold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.learnPathCompleteTitle(topicName),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: DeenColors.primaryText(dark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.learnPathCompleteMessage(lessonCount),
                style: TextStyle(fontSize: 14, color: DeenColors.textMuted(dark)),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => QuizScreen(category: category)),
                  ),
                  child: Text(l10n.learnTakeAssessmentButton),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Text(l10n.learnSkipForNowButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
