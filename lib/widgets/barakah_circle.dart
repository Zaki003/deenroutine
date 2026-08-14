import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/deen_colors.dart';

/// The "Barakah Circle" progress ring shown on the Dashboard (FR-06):
/// a gold arc with the done/total count in the middle. Eases into a new
/// percentage rather than snapping, and celebrates with a glow + spark burst
/// the moment every habit for the day is done.
class BarakahCircle extends StatefulWidget {
  final int done;
  final int total;
  final bool dark;
  final double size;

  const BarakahCircle({
    super.key,
    required this.done,
    required this.total,
    required this.dark,
    this.size = 112,
  });

  @override
  State<BarakahCircle> createState() => _BarakahCircleState();
}

class _BarakahCircleState extends State<BarakahCircle> with TickerProviderStateMixin {
  late final AnimationController _fillController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _celebrateController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final List<_Spark> _sparks = _generateSparks(9);

  double _fromPercentage = 0;
  double _toPercentage = 0;
  int _fromDone = 0;
  int _toDone = 0;

  double get _targetPercentage => widget.total == 0 ? 0.0 : widget.done / widget.total;

  @override
  void initState() {
    super.initState();
    _fromPercentage = _toPercentage = _targetPercentage;
    _fromDone = _toDone = widget.done;
  }

  @override
  void didUpdateWidget(covariant BarakahCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.done == widget.done && oldWidget.total == widget.total) return;

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    _fromPercentage = _toPercentage;
    _fromDone = _toDone;
    _toPercentage = _targetPercentage;
    _toDone = widget.done;

    _fillController..stop()..reset();
    if (reduceMotion) {
      _fillController.value = 1;
    } else {
      _fillController.forward();
    }

    final justCompleted = widget.total > 0 && widget.done == widget.total && _fromDone != widget.total;
    if (justCompleted && !reduceMotion) {
      _celebrateController..stop()..reset()..forward();
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  List<_Spark> _generateSparks(int count) {
    final rng = Random(7);
    return List.generate(count, (i) {
      final angle = (2 * pi * i / count) + (rng.nextDouble() - 0.5) * 0.5;
      final distance = 34.0 + rng.nextDouble() * 16;
      final rotation = (rng.nextDouble() - 0.5) * 2.4;
      return _Spark(angle: angle, distance: distance, rotation: rotation);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fillController, _celebrateController]),
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_fillController.value);
          final percentage = ui.lerpDouble(_fromPercentage, _toPercentage, t)!;
          final shownDone = ui.lerpDouble(_fromDone.toDouble(), _toDone.toDouble(), t)!.round();
          final ct = _celebrateController.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              if (ct > 0 && ct < 1)
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DeenColors.gold.withValues(alpha: 0.55 * (1 - ct)),
                        blurRadius: 10 + 14 * ct,
                        spreadRadius: 20 * ct,
                      ),
                    ],
                  ),
                ),
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  percentage: percentage,
                  trackColor: widget.dark
                      ? Colors.white.withValues(alpha: 0.10)
                      : DeenColors.primary.withValues(alpha: 0.12),
                  progressColor: DeenColors.gold,
                ),
              ),
              if (ct > 0)
                ..._sparks.map((spark) {
                  final opacity = (1 - ct).clamp(0.0, 1.0);
                  final scale = ui.lerpDouble(0.3, 1.0, ct)!;
                  final dist = spark.distance * ct;
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(cos(spark.angle) * dist, sin(spark.angle) * dist),
                      child: Transform.rotate(
                        angle: spark.rotation * ct,
                        child: Transform.scale(
                          scale: scale,
                          child: const Icon(Icons.auto_awesome, size: 11, color: DeenColors.gold),
                        ),
                      ),
                    ),
                  );
                }),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$shownDone/${widget.total}',
                    style: GoogleFonts.amiri(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: DeenColors.primaryText(widget.dark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      color: DeenColors.gold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Spark {
  final double angle;
  final double distance;
  final double rotation;

  const _Spark({required this.angle, required this.distance, required this.rotation});
}

class _RingPainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    final backgroundPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * pi * percentage.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percentage != percentage ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
