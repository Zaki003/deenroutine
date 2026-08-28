import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/deen_colors.dart';
import 'star_pattern.dart';

/// Themed replacement for bare Material empty/error placeholders (an
/// unstyled `Center(Text(...))`, or a section that just silently vanishes)
/// — an icon in a tinted circle plus title/message.
///
/// [compact] picks the layout. The default vertical layout centers
/// everything for a whole empty content area (e.g. no quiz questions in the
/// bank) and sits directly on the screen's own background, matching how
/// "no habits yet" already read before this widget existed. `compact: true`
/// lays out a smaller horizontal card — for a single section that failed
/// within an otherwise-populated screen (e.g. the prayer card when
/// offline) — behind the same faint gold [StarPattern] texture already
/// used on every other bordered card in the app (the quote card, the
/// Barakah Circle card, the quiz tab's best-score banner), with an optional
/// trailing retry action.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String message;
  final bool dark;
  final bool compact;
  final Color? iconColor;
  final Color? iconBackground;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateCard({
    super.key,
    required this.icon,
    this.title,
    required this.message,
    required this.dark,
    this.compact = false,
    this.iconColor,
    this.iconBackground,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final fg = iconColor ?? DeenColors.gold;
    final bg = iconBackground ?? DeenColors.panelBackground(dark);
    final iconCircle = Container(
      width: compact ? 44 : 56,
      height: compact ? 44 : 56,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Icon(icon, size: compact ? 20 : 26, color: fg),
    );

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DeenColors.cardBackground(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DeenColors.cardBorder(dark)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            StarPattern(opacity: dark ? 0.06 : 0.08, color: DeenColors.gold),
            Row(
              children: [
                iconCircle,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DeenColors.primaryText(dark),
                        ),
                      ),
                      if (title != null) ...[
                        const SizedBox(height: 2),
                        Text(message,
                            style: TextStyle(fontSize: 12.5, color: DeenColors.textMuted(dark))),
                      ],
                    ],
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconCircle,
          const SizedBox(height: 16),
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DeenColors.primaryText(dark),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: title != null ? 13 : 14,
              fontWeight: title != null ? FontWeight.normal : FontWeight.w600,
              color: title != null ? DeenColors.textMuted(dark) : DeenColors.primaryText(dark),
            ),
          ),
        ],
      ),
    );
  }
}
