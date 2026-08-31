import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';
import 'onboarding_scaffold.dart';

/// Body for a permission-priming step (location, notification, exact-alarm):
/// icon in a tinted circle, headline, body copy, full-width primary button,
/// optional secondary text button. The three priming screens differ only in
/// icon/tint/copy/behavior, never layout.
class OnboardingPermissionPrimer extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String headline;
  final String body;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool busy;

  const OnboardingPermissionPrimer({
    super.key,
    required this.icon,
    required this.tint,
    required this.headline,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OnboardingStaggerIn(
                  index: 0,
                  child: Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: tint.withValues(alpha: 0.15)),
                    child: Icon(icon, size: 40, color: tint),
                  ),
                ),
                const SizedBox(height: 24),
                OnboardingStaggerIn(
                  index: 1,
                  child: Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: DeenColors.primaryText(dark)),
                  ),
                ),
                const SizedBox(height: 10),
                OnboardingStaggerIn(
                  index: 2,
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, height: 1.5, color: DeenColors.textMuted(dark)),
                  ),
                ),
              ],
            ),
          ),
        ),
        OnboardingStaggerIn(
          index: 3,
          child: Column(
            children: [
              FilledButton(
                onPressed: busy ? null : onPrimary,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(primaryLabel),
              ),
              if (secondaryLabel != null)
                TextButton(onPressed: busy ? null : onSecondary, child: Text(secondaryLabel!)),
            ],
          ),
        ),
      ],
    );
  }
}
