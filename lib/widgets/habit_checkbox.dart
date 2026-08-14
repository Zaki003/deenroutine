import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';

/// Animated circular checkbox used to mark a habit done: the fill scales in
/// and the tick draws itself, instead of the state just flipping instantly.
class HabitCheckbox extends StatefulWidget {
  final bool done;
  final bool dark;
  final VoidCallback onTap;
  final double size;

  const HabitCheckbox({
    super.key,
    required this.done,
    required this.dark,
    required this.onTap,
    this.size = 22,
  });

  @override
  State<HabitCheckbox> createState() => _HabitCheckboxState();
}

class _HabitCheckboxState extends State<HabitCheckbox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.done ? 1 : 0,
  );
  late final Animation<double> _fill = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
    reverseCurve: Curves.easeIn,
  );
  late final Animation<double> _tick = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    reverseCurve: Curves.easeIn,
  );

  @override
  void didUpdateWidget(covariant HabitCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.done != widget.done) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (widget.done) {
        _controller.forward(from: reduceMotion ? 1 : _controller.value);
      } else {
        _controller.reverse(from: reduceMotion ? 0 : _controller.value);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = DeenColors.outlineFaint(widget.dark);
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _CheckboxPainter(
                fillT: _fill.value.clamp(0.0, 1.0),
                tickT: _tick.value.clamp(0.0, 1.0),
                trackColor: track,
                fillColor: DeenColors.primary,
                tickColor: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckboxPainter extends CustomPainter {
  final double fillT;
  final double tickT;
  final Color trackColor;
  final Color fillColor;
  final Color tickColor;

  _CheckboxPainter({
    required this.fillT,
    required this.tickT,
    required this.trackColor,
    required this.fillColor,
    required this.tickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Color.lerp(trackColor, fillColor, fillT)!;
    canvas.drawCircle(center, radius - 1, borderPaint);

    if (fillT > 0) {
      final fillPaint = Paint()..color = fillColor;
      canvas.drawCircle(center, (radius - 1) * fillT, fillPaint);
    }

    if (tickT > 0) {
      final path = Path()
        ..moveTo(size.width * 0.26, size.height * 0.54)
        ..lineTo(size.width * 0.43, size.height * 0.70)
        ..lineTo(size.width * 0.76, size.height * 0.32);

      final metrics = path.computeMetrics().first;
      final extracted = metrics.extractPath(0, metrics.length * tickT);
      final tickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = tickColor;
      canvas.drawPath(extracted, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckboxPainter oldDelegate) =>
      oldDelegate.fillT != fillT || oldDelegate.tickT != tickT || oldDelegate.trackColor != trackColor;
}
