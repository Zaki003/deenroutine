import 'package:flutter/material.dart';
import '../theme/deen_colors.dart';

/// A single tappable settings/account row: icon, label, optional trailing
/// value. Shared between the profile screen (just Favorites) and the
/// settings screen (everything else) so both stay visually identical.
class AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dark;
  final Color? color;
  final String? trailingText;
  /// Shows a chevron alongside [trailingText] instead of the default
  /// text-only display — for a row where tapping genuinely navigates
  /// somewhere. Ignored when [trailingText] is null.
  final bool showChevron;
  final VoidCallback onTap;

  const AccountRow({
    super.key,
    required this.icon,
    required this.label,
    required this.dark,
    this.color,
    this.trailingText,
    this.showChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color ?? DeenColors.textMuted(dark)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 13.5, color: color ?? DeenColors.primaryText(dark)),
            ),
            // A fixed gap here (rather than relying on spaceBetween to
            // supply one) is what keeps the label and a long trailing value
            // - e.g. "Umm al-Qura · Standard" - from ending up flush against
            // each other with no breathing room once the value's own
            // ellipsis has already done all the shrinking it can.
            const SizedBox(width: 8),
            Expanded(
              child: trailingText != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            trailingText!,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark)),
                          ),
                        ),
                        if (showChevron) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 16, color: DeenColors.textMuted(dark)),
                        ],
                      ],
                    )
                  : (color == null
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.chevron_right_rounded,
                              size: 18, color: DeenColors.textMuted(dark)),
                        )
                      : const SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}
