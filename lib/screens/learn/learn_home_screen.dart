import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/learn_progress.dart';
import '../../models/quiz_question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learn_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/learn_topic_labels.dart';
import 'lesson_screen.dart';
import 'path_complete_screen.dart';

/// Learn tab landing: a winding trail of the 10 topics in
/// [LearnProvider.kTopicOrder], each unlocking once the one before it is
/// complete (lessons walked + assessment taken).
class LearnHomeScreen extends StatefulWidget {
  const LearnHomeScreen({super.key});

  @override
  State<LearnHomeScreen> createState() => _LearnHomeScreenState();
}

class _LearnHomeScreenState extends State<LearnHomeScreen> {
  late final LearnProvider _learnProvider;

  @override
  void initState() {
    super.initState();
    _learnProvider = context.read<LearnProvider>();
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    _learnProvider.listenToProgress(uid);
  }

  @override
  void dispose() {
    _learnProvider.stopListening();
    super.dispose();
  }

  void _openTopic(BuildContext context, String category) {
    if (!_learnProvider.isUnlocked(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.learnTopicLocked)),
      );
      return;
    }
    // Already fully done (lessons + assessment) - go straight to the
    // path-complete screen (which itself routes back into the assessment
    // if the user wants to retake it) rather than replaying every lesson.
    if (_learnProvider.isTopicComplete(category)) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FutureBuilder<List<QuizQuestion>>(
          future: _learnProvider.loadLessonQuestions(category),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return PathCompleteScreen(category: category, lessonCount: snapshot.data!.length);
          },
        ),
      ));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonScreen(category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final learnProvider = context.watch<LearnProvider>();

    return ColoredBox(
      color: DeenColors.surface(dark),
      child: SafeArea(
        child: !learnProvider.hasLoadedOnce
            ? Center(child: CircularProgressIndicator(color: DeenColors.gold))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    l10n.learnTabTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: DeenColors.primaryText(dark),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Positioned(
                        top: 28,
                        bottom: 28,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 2,
                            color: DeenColors.primaryLight.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          for (var i = 0; i < LearnProvider.kTopicOrder.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Align(
                                alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
                                child: _TopicNode(
                                  category: LearnProvider.kTopicOrder[i],
                                  dark: dark,
                                  unlocked: learnProvider.isUnlocked(LearnProvider.kTopicOrder[i]),
                                  complete:
                                      learnProvider.isTopicComplete(LearnProvider.kTopicOrder[i]),
                                  learnProvider: learnProvider,
                                  onTap: () =>
                                      _openTopic(context, LearnProvider.kTopicOrder[i]),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _TopicNode extends StatelessWidget {
  final String category;
  final bool dark;
  final bool unlocked;
  final bool complete;
  final LearnProvider learnProvider;
  final VoidCallback onTap;

  const _TopicNode({
    required this.category,
    required this.dark,
    required this.unlocked,
    required this.complete,
    required this.learnProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topicName = learnTopicLabel(l10n, category);

    final Color circleColor;
    final Widget icon;
    if (complete) {
      circleColor = DeenColors.gold;
      icon = const Icon(Icons.check_rounded, color: DeenColors.ink, size: 22);
    } else if (unlocked) {
      circleColor = DeenColors.ink;
      icon = const Icon(Icons.local_fire_department_rounded, color: DeenColors.gold, size: 20);
    } else {
      circleColor = DeenColors.cardBackground(dark);
      icon = Icon(Icons.lock_rounded, color: DeenColors.textMuted(dark), size: 18);
    }

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                border: unlocked && !complete
                    ? Border.all(color: DeenColors.gold, width: 2.5)
                    : null,
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: 6),
            Text(
              topicName,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: DeenColors.primaryText(dark),
              ),
            ),
            const SizedBox(height: 2),
            if (complete)
              _ScoreChip(progress: learnProvider.progressFor(category), dark: dark)
            else if (unlocked)
              _LessonsChip(category: category, learnProvider: learnProvider, dark: dark),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final LearnProgress? progress;
  final bool dark;

  const _ScoreChip({required this.progress, required this.dark});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    if (p == null) return const SizedBox.shrink();
    return Text(
      '${p.assessmentScore}/${p.assessmentTotal}',
      style: TextStyle(fontSize: 10.5, color: DeenColors.textMuted(dark)),
    );
  }
}

/// Fetches just [category]'s total question count to pair with the
/// already-known completed count - a small accepted double-fetch against
/// what LessonScreen will fetch again on entry, traded for keeping both
/// widgets independently simple.
class _LessonsChip extends StatelessWidget {
  final String category;
  final LearnProvider learnProvider;
  final bool dark;

  const _LessonsChip({required this.category, required this.learnProvider, required this.dark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<QuizQuestion>>(
      future: learnProvider.loadLessonQuestions(category),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return Text(
          l10n.learnLessonsProgress(learnProvider.lessonsCompletedCount(category), snapshot.data!.length),
          style: TextStyle(fontSize: 10.5, color: DeenColors.textMuted(dark)),
        );
      },
    );
  }
}
