import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';

/// Flame + streak-day count, opacity scaling with streak length so a longer
/// streak reads as a brighter flame at a glance. The flame idles with a
/// gentle flicker, and pops/brightens for a moment whenever [streak] changes.
class StreakBadge extends StatefulWidget {
  final int streak;
  final bool dark;

  const StreakBadge({super.key, required this.streak, required this.dark});

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge> with TickerProviderStateMixin {
  late final AnimationController _idleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _popController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.32).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(
        tween: Tween(begin: 1.32, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 60),
  ]).animate(_popController);
  late final Animation<double> _popGlow = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 60),
  ]).animate(_popController);

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      if (_reduceMotion) {
        _idleController.stop();
      } else if (!_idleController.isAnimating) {
        _idleController.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streak != widget.streak && !_reduceMotion) {
      _popController..stop()..reset()..forward();
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = (widget.streak / 30).clamp(0.0, 1.0);
    final baseAlpha = 0.35 + intensity * 0.65;

    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _popController]),
      builder: (context, _) {
        final flicker = _reduceMotion ? 0.0 : Curves.easeInOut.transform(_idleController.value);
        final alpha = (baseAlpha + _popGlow.value * (1 - baseAlpha)).clamp(0.0, 1.0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 1 + flicker * 0.06,
              child: Icon(
                Icons.local_fire_department,
                size: 15,
                color: DeenColors.gold.withValues(alpha: alpha),
              ),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: _popScale.value,
              child: Text(
                '${widget.streak}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.dark ? DeenColors.goldSoft : DeenColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
