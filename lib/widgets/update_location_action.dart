import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/city.dart';
import '../providers/prayer_provider.dart';
import '../screens/prayer/city_search_screen.dart';
import '../theme/deen_colors.dart';
import '../utils/prayer_error_messages.dart';

enum _LocationChoice { gps, city }

/// Shared "set location" entry point, triggered from the small location icon
/// on [GradientHeroCard]. Opens a sheet offering GPS or a manually typed
/// city, then applies whichever was picked — kept in one place since both
/// the Dashboard and Prayer screen wire it up identically.
Future<void> confirmUpdateLocation(BuildContext context) async {
  final choice = await showModalBottomSheet<_LocationChoice>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _LocationChoiceSheet(),
  );
  if (choice == null || !context.mounted) return;

  if (choice == _LocationChoice.gps) {
    await _updateFromGps(context);
  } else {
    await _pickCity(context);
  }
}

Future<void> _updateFromGps(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final provider = context.read<PrayerProvider>();
  final success = await provider.updateLocation();
  if (!context.mounted) return;
  _showResult(context, l10n, success, provider);
}

Future<void> _pickCity(BuildContext context) async {
  final city = await Navigator.push<City>(
    context,
    MaterialPageRoute(builder: (_) => const CitySearchScreen()),
  );
  if (city == null || !context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final provider = context.read<PrayerProvider>();
  final success = await provider.setManualCity(city);
  if (!context.mounted) return;
  _showResult(context, l10n, success, provider);
}

void _showResult(
  BuildContext context,
  AppLocalizations l10n,
  bool success,
  PrayerProvider provider,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? l10n.updateLocationSuccess
            : prayerErrorMessage(l10n, provider.errorType!, provider.errorDetail),
      ),
    ),
  );
}

class _LocationChoiceSheet extends StatelessWidget {
  const _LocationChoiceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrayerProvider>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.updateLocationTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              provider.isManualLocation
                  ? l10n.currentLocationCity(provider.manualCityLabel!)
                  : l10n.currentLocationGps,
              style: TextStyle(fontSize: 12, color: DeenColors.textMuted(Theme.of(context).brightness == Brightness.dark)),
            ),
            const SizedBox(height: 14),
            _ChoiceRow(
              icon: Icons.my_location,
              iconBackground: DeenColors.primary,
              title: l10n.updateLocationConfirm,
              subtitle: l10n.useCurrentLocationSubtitle,
              onTap: () => Navigator.pop(context, _LocationChoice.gps),
            ),
            _ChoiceRow(
              icon: Icons.search,
              iconBackground: DeenColors.gold,
              title: l10n.enterCityTitle,
              subtitle: l10n.enterCitySubtitle,
              onTap: () => Navigator.pop(context, _LocationChoice.city),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceRow({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: iconBackground),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: DeenColors.primaryText(dark))),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
