import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/daily_quote.dart';
import '../theme/deen_colors.dart';
import 'star_pattern.dart';

/// The daily-ayah/hadith panel - shown on the dashboard for today's quote,
/// and reused on the favourites screen so a saved quote looks identical to
/// where it was favourited from.
class QuoteCard extends StatelessWidget {
  final DailyQuote quote;
  final bool isBangla;
  final bool dark;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.isBangla,
    required this.dark,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeenColors.panelBackground(dark),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          StarPattern(opacity: dark ? 0.06 : 0.08, color: DeenColors.gold),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.displayText(isBangla),
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        height: 1.5,
                        color: dark ? DeenColors.goldSoft : DeenColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      quote.source,
                      style: TextStyle(fontSize: 11, color: DeenColors.textMuted(dark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _FavoriteHeartButton(active: isFavorite, dark: dark, onTap: onToggleFavorite),
            ],
          ),
        ],
      ),
    );
  }
}

/// A quiet toggle rather than a loud "add" button: outline heart at rest,
/// fills with [DeenColors.gold] (the same warm accent the card's own star
/// pattern and dark-mode text already use) once saved, with a gentle scale
/// pop instead of an instant icon swap - matching [HabitCheckbox]'s existing
/// house style of animating state changes rather than flipping them.
///
/// Built on [IconButton] rather than a bare [InkResponse]: a hand-rolled
/// tappable icon with no text of its own has nothing to anchor a distinct
/// accessibility node, and a `uiautomator dump` against this card confirmed
/// it was merging into the surrounding quote text as one opaque node -
/// TalkBack would announce the quote but never expose the button.
/// [IconButton]'s own `tooltip` gives it the `button: true` semantics
/// (labelled, independently focusable) that fixes that, for both the visual
/// long-press tooltip and the screen-reader label.
class _FavoriteHeartButton extends StatelessWidget {
  final bool active;
  final bool dark;
  final VoidCallback onTap;

  const _FavoriteHeartButton({required this.active, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      onPressed: onTap,
      tooltip: active ? l10n.favoriteRemoveTooltip : l10n.favoriteAddTooltip,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(6),
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(active),
          size: 20,
          color: active ? DeenColors.gold : DeenColors.textMuted(dark),
        ),
      ),
    );
  }
}
