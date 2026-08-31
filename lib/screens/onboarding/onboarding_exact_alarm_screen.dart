import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/onboarding_permission_primer.dart';
import '../../widgets/onboarding_scaffold.dart';
import 'onboarding_habit_picker_screen.dart';

/// Only ever pushed when [Permission.scheduleExactAlarm] isn't already
/// granted (see OnboardingNotificationScreen._advance) — no defensive
/// re-check needed on entry.
class OnboardingExactAlarmScreen extends StatefulWidget {
  const OnboardingExactAlarmScreen({super.key});

  @override
  State<OnboardingExactAlarmScreen> createState() => _OnboardingExactAlarmScreenState();
}

class _OnboardingExactAlarmScreenState extends State<OnboardingExactAlarmScreen> {
  bool _busy = false;

  Future<void> _openSettings() async {
    setState(() => _busy = true);
    // .request() launches Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM
    // scoped to this app directly — no openAppSettings() detour needed.
    // No reliable synchronous "did they flip it" signal on return, so this
    // advances regardless, same as the location/notification steps.
    await Permission.scheduleExactAlarm.request();
    if (!mounted) return;
    _advance();
  }

  void _advance() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const OnboardingHabitPickerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingScaffold(
      activeDotIndex: 2,
      child: OnboardingPermissionPrimer(
        icon: Icons.alarm_outlined,
        tint: DeenColors.rust,
        headline: l10n.onboardingExactAlarmHeadline,
        body: l10n.onboardingExactAlarmBody,
        primaryLabel: l10n.onboardingOpenSettingsButton,
        onPrimary: _openSettings,
        secondaryLabel: l10n.onboardingExactAlarmLaterButton,
        onSecondary: _advance,
        busy: _busy,
      ),
    );
  }
}
