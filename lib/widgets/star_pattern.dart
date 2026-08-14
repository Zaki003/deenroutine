import 'dart:math';
import 'package:flutter/material.dart';

/// Faint tiled 10-point star texture used behind hero/quote panels,
/// matching the approved mockup's decorative background.
class StarPattern extends StatelessWidget {
  final double opacity;
  final Color color;

  const StarPattern({super.key, this.opacity = 0.05, this.color = const Color(0xFFC9A24B)});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: CustomPaint(painter: _StarPatternPainter(color: color)),
        ),
      ),
    );
  }
}

class _StarPatternPainter extends CustomPainter {
  final Color color;
  static const double _tile = 26;

  _StarPatternPainter({required this.color});

  Path _starPath(Offset center, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = (-90 + i * 36) * pi / 180;
      final radius = i.isEven ? r : r * 0.42;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cols = (size.width / _tile).ceil() + 1;
    final rows = (size.height / _tile).ceil() + 1;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final center = Offset(col * _tile + _tile / 2, row * _tile + _tile / 2);
        canvas.drawPath(_starPath(center, _tile * 0.34), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
