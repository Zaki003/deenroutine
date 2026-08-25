import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';
import '../utils/app_theme.dart';
import 'habit_checkbox.dart';

/// Leading dashboard-row control for numeric/timer habits: a progress ring
/// with a center glyph while incomplete, converging on the exact same
/// solid-fill tick [HabitCheckbox] draws once complete — every tracking
/// type looks identical at "done", however it got there.
class HabitProgressRing extends StatelessWidget {
  final double progress; // 0.0..1.0
  final bool done;
  final bool dark;
  final VoidCallback onTap;
  final Widget centerGlyph;
  final double size;

  const HabitProgressRing({
    super.key,
    required this.progress,
    required this.done,
    required this.dark,
    required this.onTap,
    required this.centerGlyph,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    // Composes HabitCheckbox directly for the completed state rather than
    // re-implementing its tick-draw — every tracking type should look
    // identical once done, not just similar.
    if (done) {
      return HabitCheckbox(done: true, dark: dark, onTap: onTap, size: size);
    }
    final track = Theme.of(context).colorScheme.progressTrack;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _ProgressRingPainter(
                progress: progress.clamp(0.0, 1.0),
                trackColor: track,
                progressColor: DeenColors.primary,
                strokeWidth: size / 11,
              ),
            ),
            centerGlyph,
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
