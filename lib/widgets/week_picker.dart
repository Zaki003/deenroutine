import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';

/// Read-only row of 7 day markers showing which days a habit was completed
/// this week. [days] and [labels] must both have length 7, in display order.
/// A day that flips done/undone pops in place rather than just recoloring.
class WeekPicker extends StatefulWidget {
  final List<bool> days;
  final List<String> labels;
  final bool dark;

  const WeekPicker({
    super.key,
    required this.days,
    required this.labels,
    required this.dark,
  });

  @override
  State<WeekPicker> createState() => _WeekPickerState();
}

class _WeekPickerState extends State<WeekPicker> with TickerProviderStateMixin {
  late final List<AnimationController> _pops = List.generate(
    7,
    (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1),
  );

  @override
  void didUpdateWidget(covariant WeekPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    for (var i = 0; i < 7 && i < widget.days.length && i < oldWidget.days.length; i++) {
      if (oldWidget.days[i] != widget.days[i] && !reduceMotion) {
        _pops[i]..stop()..reset()..forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _pops) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final done = widget.days[i];
        return Padding(
          padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
          child: AnimatedBuilder(
            animation: _pops[i],
            builder: (context, child) {
              final scale = 0.6 + 0.4 * Curves.easeOutBack.transform(_pops[i].value);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? DeenColors.primary : Colors.transparent,
                border: Border.all(
                  color: done ? DeenColors.primary : DeenColors.outlineFaint(widget.dark),
                ),
              ),
              child: Text(
                widget.labels[i],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: done ? Colors.white : DeenColors.textMuted(widget.dark),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
