import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';

/// Small caps-style header above a group of rows or cards — e.g.
/// "PREFERENCES", "ACCOUNT", "THIS WEEK".
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: DeenColors.textMuted(dark),
      ),
    );
  }
}
