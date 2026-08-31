import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notification_service.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/onboarding_permission_primer.dart';
import '../../widgets/onboarding_scaffold.dart';
import 'onboarding_exact_alarm_screen.dart';
import 'onboarding_habit_picker_screen.dart';

class OnboardingNotificationScreen extends StatefulWidget {
  const OnboardingNotificationScreen({super.key});

  @override
  State<OnboardingNotificationScreen> createState() => _OnboardingNotificationScreenState();
}

class _OnboardingNotificationScreenState extends State<OnboardingNotificationScreen> {
  bool _busy = false;

  Future<void> _allowNotifications() async {
    setState(() => _busy = true);
    await NotificationService().requestPermission();
    if (!mounted) return;
    await _advance();
  }

  Future<void> _skip() async {
    setState(() => _busy = true);
    await _advance();
  }

  Future<void> _advance() async {
    // Same "just don't push the route" pattern: if exact-alarm access is
    // already granted, skip the nudge screen entirely.
    final exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            exactAlarmGranted ? const OnboardingHabitPickerScreen() : const OnboardingExactAlarmScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingScaffold(
      activeDotIndex: 1,
      child: OnboardingPermissionPrimer(
        icon: Icons.notifications_outlined,
        tint: DeenColors.gold,
        headline: l10n.onboardingNotificationHeadline,
        body: l10n.onboardingNotificationBody,
        primaryLabel: l10n.onboardingAllowNotificationsButton,
        onPrimary: _allowNotifications,
        secondaryLabel: l10n.onboardingSkipNotificationsButton,
        onSecondary: _skip,
        busy: _busy,
      ),
    );
  }
}
