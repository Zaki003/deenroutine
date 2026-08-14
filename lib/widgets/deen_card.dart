import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';

/// Flat rounded card matching the mockup's `Card` component: themed
/// background + hairline border, no elevation.
class DeenCard extends StatelessWidget {
  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const DeenCard({
    super.key,
    required this.child,
    required this.dark,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: DeenColors.cardBackground(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeenColors.cardBorder(dark)),
      ),
      child: child,
    );
  }
}
