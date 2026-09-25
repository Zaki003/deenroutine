import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';
import 'deen_card.dart';

/// A small label-over-value card, as used in rows of stats on the Profile.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;

  const StatTile({super.key, required this.label, required this.value, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: DeenCard(
        dark: dark,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: DeenColors.textMuted(dark))),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DeenColors.primaryText(dark)),
            ),
          ],
        ),
      ),
    );
  }
}
