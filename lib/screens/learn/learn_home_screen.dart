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
    final completedCount =
        LearnProvider.kTopicOrder.where(learnProvider.isTopicComplete).length;

    return ColoredBox(
      color: DeenColors.surface(dark),
      child: SafeArea(
        child: !learnProvider.hasLoadedOnce
            ? Center(child: CircularProgressIndicator(color: DeenColors.gold))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.learnTabTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: DeenColors.primaryText(dark),
                        ),
                      ),
                      Text(
                        l10n.learnPathProgress(completedCount, LearnProvider.kTopicOrder.length),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: DeenColors.textMuted(dark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completedCount / LearnProvider.kTopicOrder.length,
                      minHeight: 6,
                      backgroundColor: DeenColors.trackLine(dark),
                      valueColor: const AlwaysStoppedAnimation(DeenColors.gold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Trail(
                    dark: dark,
                    learnProvider: learnProvider,
                    onOpenTopic: (category) => _openTopic(context, category),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The winding path itself: a curve threaded through every node's actual
/// center (via [_TrailPainter]) rather than a straight line floating behind
/// them, plus a milestone label every few topics to break up the scroll.
class _Trail extends StatelessWidget {
  static const double _rowHeight = 128;
  static const double _nodeSlotWidth = 96;
  static const double _laneInset = 16;
  static const Set<int> _milestoneAfter = {2, 5, 8};

  final bool dark;
  final LearnProvider learnProvider;
  final void Function(String category) onOpenTopic;

  const _Trail({required this.dark, required this.learnProvider, required this.onOpenTopic});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = LearnProvider.kTopicOrder.length;
    final totalHeight = count * _rowHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftX = _laneInset + _nodeSlotWidth / 2;
        final rightX = constraints.maxWidth - _laneInset - _nodeSlotWidth / 2;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    count: count,
                    rowHeight: _rowHeight,
                    leftX: leftX,
                    rightX: rightX,
                    color: DeenColors.primaryLight.withValues(alpha: 0.35),
                  ),
                ),
              ),
              for (var i = 0; i < count; i++) ...[
                Positioned(
                  top: i * _rowHeight,
                  left: i.isEven ? _laneInset : null,
                  right: i.isEven ? null : _laneInset,
                  width: _nodeSlotWidth,
                  child: _TopicNode(
                    category: LearnProvider.kTopicOrder[i],
                    dark: dark,
                    unlocked: learnProvider.isUnlocked(LearnProvider.kTopicOrder[i]),
                    complete: learnProvider.isTopicComplete(LearnProvider.kTopicOrder[i]),
                    learnProvider: learnProvider,
                    onTap: () => onOpenTopic(LearnProvider.kTopicOrder[i]),
                  ),
                ),
                if (_milestoneAfter.contains(i))
                  Positioned(
                    top: (i + 1) * _rowHeight - 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        l10n.learnMilestoneLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: DeenColors.textMuted(dark),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TrailPainter extends CustomPainter {
  final int count;
  final double rowHeight;
  final double leftX;
  final double rightX;
  final Color color;

  const _TrailPainter({
    required this.count,
    required this.rowHeight,
    required this.leftX,
    required this.rightX,
    required this.color,
  });

  Offset _centerFor(int i) => Offset(i.isEven ? leftX : rightX, i * rowHeight + 24);

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(_centerFor(0).dx, _centerFor(0).dy);
    for (var i = 1; i < count; i++) {
      final prev = _centerFor(i - 1);
      final curr = _centerFor(i);
      final midY = (prev.dy + curr.dy) / 2;
      path.cubicTo(prev.dx, midY, curr.dx, midY, curr.dx, curr.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.leftX != leftX ||
      oldDelegate.rightX != rightX ||
      oldDelegate.color != color;
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
      icon = const Icon(Icons.auto_stories_rounded, color: DeenColors.gold, size: 20);
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
