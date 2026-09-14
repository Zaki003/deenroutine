import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// One selectable answer option, shared by the quiz assessment and the
/// Learn lesson walkthrough - both need the same four visual states
/// (unanswered / selected / correct / wrong).
class QuizOptionTile extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool isCorrectAnswer;
  final bool answered;
  final VoidCallback onTap;

  const QuizOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isCorrectAnswer,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color background = theme.colorScheme.secondaryContainer;
    Color foreground = theme.colorScheme.onSecondaryContainer;
    Color borderColor = Colors.transparent;
    IconData? trailingIcon;

    if (answered) {
      if (isCorrectAnswer) {
        background = theme.colorScheme.successContainer;
        foreground = theme.colorScheme.onSuccessContainer;
        borderColor = theme.colorScheme.success;
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected) {
        background = theme.colorScheme.errorSurface;
        foreground = theme.colorScheme.onErrorContainer;
        borderColor = theme.colorScheme.error;
        trailingIcon = Icons.cancel_rounded;
      } else {
        background = theme.colorScheme.surfaceContainerHighest;
        foreground = theme.colorScheme.onSurfaceVariant;
      }
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      background = theme.colorScheme.primary.withValues(alpha: 0.15);
      foreground = theme.colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: answered ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: isSelected || (answered && isCorrectAnswer)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  Icon(
                    trailingIcon,
                    color: isCorrectAnswer
                        ? theme.colorScheme.success
                        : theme.colorScheme.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
