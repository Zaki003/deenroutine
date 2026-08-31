import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/city.dart';
import '../../providers/prayer_provider.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/onboarding_permission_primer.dart';
import '../../widgets/onboarding_scaffold.dart';
import '../prayer/city_search_screen.dart';
import 'onboarding_notification_screen.dart';

class OnboardingLocationScreen extends StatefulWidget {
  const OnboardingLocationScreen({super.key});

  @override
  State<OnboardingLocationScreen> createState() => _OnboardingLocationScreenState();
}

class _OnboardingLocationScreenState extends State<OnboardingLocationScreen> {
  bool _busy = false;

  Future<void> _allowLocation() async {
    setState(() => _busy = true);
    // updateLocation(), not loadPrayerTimes() — the latter deliberately
    // avoids touching GPS whenever a same-day cache or any previously-saved
    // lat/lng exists (SharedPreferences is device-scoped, not per-account,
    // so a fresh registration can still inherit a stale location from
    // earlier testing/another account on this device). updateLocation()
    // unconditionally re-reads GPS, which is what's needed to actually
    // trigger the OS permission dialog here.
    //
    // Outcome ignored deliberately: granted, denied, or errored all just
    // advance — Dashboard's _PrayerHero and the Prayer tab already have a
    // themed offline/error state with its own Retry action.
    await context.read<PrayerProvider>().updateLocation();
    if (!mounted) return;
    _advance();
  }

  Future<void> _enterCityManually() async {
    final city = await Navigator.push<City>(
      context,
      MaterialPageRoute(builder: (_) => const CitySearchScreen()),
    );
    // Backed out without picking a city: stay put rather than silently
    // skipping the whole location step.
    if (city == null || !mounted) return;
    setState(() => _busy = true);
    await context.read<PrayerProvider>().setManualCity(city);
    if (!mounted) return;
    _advance();
  }

  void _advance() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const OnboardingNotificationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingScaffold(
      activeDotIndex: 0,
      child: OnboardingPermissionPrimer(
        icon: Icons.location_on_outlined,
        tint: DeenColors.gold,
        headline: l10n.onboardingLocationHeadline,
        body: l10n.onboardingLocationBody,
        primaryLabel: l10n.onboardingAllowLocationButton,
        onPrimary: _allowLocation,
        secondaryLabel: l10n.onboardingEnterCityManually,
        onSecondary: _enterCityManually,
        busy: _busy,
      ),
    );
  }
}
