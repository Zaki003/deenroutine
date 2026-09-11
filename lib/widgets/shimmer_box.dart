import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';

/// A gently pulsing placeholder rectangle, sized and positioned like the
/// real content it stands in for so nothing shifts once that content
/// arrives — used across the dashboard's skeleton loading states.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final bool dark;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    required this.dark,
    this.radius = 6,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final alpha = 0.12 + t * 0.16;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: DeenColors.textMuted(widget.dark).withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
