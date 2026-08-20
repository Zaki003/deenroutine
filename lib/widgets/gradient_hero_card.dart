import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/deen_colors.dart';
import 'star_pattern.dart';

/// The gradient "next prayer" hero panel. [compact] renders the small
/// dashboard version (deliberately smaller than the Barakah Circle card
/// next to it); the large variant is used on the dedicated Prayer screen.
class GradientHeroCard extends StatelessWidget {
  final String eyebrow;
  final String prayerName;
  final String timeLabel;
  final String remainingLabel;
  final bool compact;
  final VoidCallback? onUpdateLocation;

  const GradientHeroCard({
    super.key,
    required this.eyebrow,
    required this.prayerName,
    required this.timeLabel,
    required this.remainingLabel,
    this.compact = false,
    this.onUpdateLocation,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 10.0 : 20.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: DeenColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          StarPattern(opacity: 0.10, color: DeenColors.gold),
          compact ? _compactContent() : _largeContent(),
          if (onUpdateLocation != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: onUpdateLocation,
                icon: const Icon(Icons.edit_location_alt_outlined),
                iconSize: compact ? 14 : 18,
                color: DeenColors.goldSoft,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                tooltip: AppLocalizations.of(context)!.updateLocationTooltip,
              ),
            ),
        ],
      ),
    );
  }

  Widget _compactContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: TextStyle(fontSize: 9.5, color: DeenColors.goldSoft, letterSpacing: 1),
            ),
            Text(
              prayerName,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '$remainingLabel · $timeLabel',
              style: const TextStyle(fontSize: 11, color: Color(0xCCFFFFFF)),
            ),
          ],
        ),
        const Icon(Icons.access_time_rounded, size: 20, color: DeenColors.goldSoft),
      ],
    );
  }

  Widget _largeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          eyebrow,
          style: TextStyle(fontSize: 11, color: DeenColors.goldSoft, letterSpacing: 1.5),
        ),
        Text(
          prayerName,
          style: GoogleFonts.amiri(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          remainingLabel,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: DeenColors.goldSoft),
        ),
        const SizedBox(height: 2),
        Text(
          timeLabel,
          style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF)),
        ),
      ],
    );
  }
}
