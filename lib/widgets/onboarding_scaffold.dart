import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';

/// Shell shared by every onboarding step: full-screen on the app's normal
/// background (matching Login/Register, not a modal/card — onboarding is a
/// dedicated sequence you move through once, not a supplementary action),
/// with small progress dots pinned to the bottom.
class OnboardingScaffold extends StatelessWidget {
  /// Fixed at 4 (location, notification, exact-alarm-or-skipped, habit
  /// picker) rather than computed dynamically. When the exact-alarm step is
  /// skipped (already granted), the indicator visibly jumps from position 1
  /// to 3 — correctly reading as "a step was skipped" — instead of every
  /// downstream screen needing a computed total threaded through its route.
  static const totalSteps = 4;

  final Widget child;

  /// Null on the welcome screen only — renders no dots row at all.
  final int? activeDotIndex;

  const OnboardingScaffold({super.key, required this.child, this.activeDotIndex});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: DeenColors.surface(dark),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            children: [
              Expanded(child: child),
              if (activeDotIndex != null) ...[
                const SizedBox(height: 20),
                _OnboardingDots(activeIndex: activeDotIndex!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  final int activeIndex;
  const _OnboardingDots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < OnboardingScaffold.totalSteps; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == activeIndex ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == activeIndex ? DeenColors.gold : DeenColors.outlineFaint(dark),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

/// Same staggered fade+slide-up reveal as [quiz_result_screen.dart]'s
/// private `_StaggerIn` (identical technique, exported here so every
/// onboarding step can share it instead of each screen re-navigating the
/// OS's own animation curves from scratch).
class OnboardingStaggerIn extends StatefulWidget {
  final int index;
  final Widget child;

  const OnboardingStaggerIn({super.key, required this.index, required this.child});

  @override
  State<OnboardingStaggerIn> createState() => _OnboardingStaggerInState();
}

class _OnboardingStaggerInState extends State<OnboardingStaggerIn> {
  bool _visible = false;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (MediaQuery.of(context).disableAnimations) {
      _visible = true;
      return;
    }
    Future.delayed(Duration(milliseconds: 550 + widget.index * 90), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.06),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
