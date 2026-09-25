import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/notification_settings_provider.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/account_row.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/section_label.dart';

/// Where the notification choices live: the daily ayah/hadith, how habit
/// reminders are worded, the optional motivation (streak reminder, Friday
/// summary, come-back message), and whether the phone is actually letting the
/// app's notifications through - the usual reason a reminder never shows up,
/// and otherwise something only visible deep in system settings.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  bool? _notificationsAllowed;
  bool? _alarmsAllowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Both grants are flipped in system settings, outside the app - coming
  /// back to the foreground is the only signal that one might have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notifications = await Permission.notification.isGranted;
    final alarms = await Permission.scheduleExactAlarm.isGranted;
    if (!mounted) return;
    setState(() {
      _notificationsAllowed = notifications;
      _alarmsAllowed = alarms;
    });
  }

  Future<void> _pickTime(
      int hour, int minute, Future<void> Function(int, int) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked != null) await onPicked(picked.hour, picked.minute);
  }

  String? _statusText(AppLocalizations l10n, bool? allowed) {
    if (allowed == null) return null;
    return allowed ? l10n.permissionAllowed : l10n.permissionNotAllowed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<NotificationSettingsProvider>();
    // Only Android has a separate "alarms & reminders" grant.
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final notificationsBlocked = _notificationsAllowed == false;
    final alarmsBlocked = isAndroid && _alarmsAllowed == false;
    final problemColor = dark ? DeenColors.rustLight : DeenColors.rust;
    final divider =
        Divider(height: 1, thickness: 1, color: DeenColors.dividerLine(dark));
    final noteStyle =
        TextStyle(fontSize: 11.5, height: 1.4, color: DeenColors.textMuted(dark));
    Widget note(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(text, style: noteStyle),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: ColoredBox(
        color: DeenColors.surface(dark),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            SectionLabel(l10n.notificationsDailyQuoteLabel),
            const SizedBox(height: 8),
            DeenCard(
              dark: dark,
              child: _SwitchWithTime(
                dark: dark,
                title: l10n.dailyQuoteNotifyTitle,
                subtitle: l10n.dailyQuoteNotifySubtitle,
                value: settings.quoteEnabled,
                onChanged: settings.loaded ? settings.setQuoteEnabled : null,
                timeLabel: l10n.dailyQuoteNotifyTimeLabel,
                hour: settings.quoteHour,
                minute: settings.quoteMinute,
                onTapTime: () => _pickTime(
                    settings.quoteHour, settings.quoteMinute, settings.setQuoteTime),
              ),
            ),
            note(l10n.dailyQuoteNotifyFootnote),
            const SizedBox(height: 20),
            SectionLabel(l10n.notificationsRemindersLabel),
            const SizedBox(height: 8),
            DeenCard(
              dark: dark,
              child: _NotificationSwitch(
                dark: dark,
                title: l10n.encouragingRemindersTitle,
                subtitle: l10n.encouragingRemindersSubtitle,
                value: settings.encouragingReminders,
                onChanged: settings.loaded ? settings.setEncouragingReminders : null,
              ),
            ),
            note(l10n.remindersSkipDoneNote),
            const SizedBox(height: 20),
            SectionLabel(l10n.notificationsNudgesLabel),
            const SizedBox(height: 8),
            DeenCard(
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SwitchWithTime(
                    dark: dark,
                    title: l10n.streakNudgeSettingTitle,
                    subtitle: l10n.streakNudgeSettingSubtitle,
                    value: settings.streakNudge,
                    onChanged: settings.loaded ? settings.setStreakNudge : null,
                    timeLabel: l10n.dailyQuoteNotifyTimeLabel,
                    hour: settings.streakHour,
                    minute: settings.streakMinute,
                    onTapTime: () => _pickTime(settings.streakHour,
                        settings.streakMinute, settings.setStreakNudgeTime),
                  ),
                  divider,
                  _NotificationSwitch(
                    dark: dark,
                    title: l10n.weeklySummarySettingTitle,
                    subtitle: l10n.weeklySummarySettingSubtitle,
                    value: settings.weeklySummary,
                    onChanged: settings.loaded ? settings.setWeeklySummary : null,
                  ),
                  divider,
                  _NotificationSwitch(
                    dark: dark,
                    title: l10n.comebackSettingTitle,
                    subtitle: l10n.comebackSettingSubtitle,
                    value: settings.comeback,
                    onChanged: settings.loaded ? settings.setComeback : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionLabel(l10n.notificationsStatusLabel),
            const SizedBox(height: 8),
            DeenCard(
              dark: dark,
              child: Column(
                children: [
                  AccountRow(
                    icon: Icons.notifications_none_rounded,
                    label: l10n.notificationsTitle,
                    dark: dark,
                    color: notificationsBlocked ? problemColor : null,
                    trailingText: _statusText(l10n, _notificationsAllowed),
                    showChevron: true,
                    // The app's own settings page: the one place the user can
                    // flip this on, or tune it, on every Android version.
                    onTap: openAppSettings,
                  ),
                  if (isAndroid) ...[
                    divider,
                    AccountRow(
                      icon: Icons.alarm_rounded,
                      label: l10n.alarmsAndRemindersLabel,
                      dark: dark,
                      color: alarmsBlocked ? problemColor : null,
                      trailingText: _statusText(l10n, _alarmsAllowed),
                      showChevron: true,
                      // Opens the exact-alarm page scoped to this app directly.
                      onTap: () => Permission.scheduleExactAlarm.request(),
                    ),
                  ],
                ],
              ),
            ),
            if (notificationsBlocked || alarmsBlocked)
              note(l10n.notificationsProblemNote),
          ],
        ),
      ),
    );
  }
}

/// A titled switch in the app's colours. On: gold on dark, teal on light -
/// DeenColors.primary alone vanishes into the dark card. Off: the muted
/// track and thumb the rest of the UI uses. SwitchListTile merges the title,
/// subtitle and state into one announcement for screen readers.
class _NotificationSwitch extends StatelessWidget {
  final bool dark;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _NotificationSwitch({
    required this.dark,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onTrack = dark ? DeenColors.gold : DeenColors.primary;
    final onThumb = dark ? DeenColors.ink : Colors.white;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DeenColors.primaryText(dark),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
              fontSize: 11.5, height: 1.4, color: DeenColors.textMuted(dark)),
        ),
      ),
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? onThumb
              : DeenColors.textMuted(dark)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? onTrack
              : DeenColors.trackLine(dark)),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Colors.transparent
              : DeenColors.outlineFaint(dark)),
    );
  }
}

/// A [_NotificationSwitch] that reveals a time row while it's on.
class _SwitchWithTime extends StatelessWidget {
  final bool dark;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String timeLabel;
  final int hour;
  final int minute;
  final VoidCallback onTapTime;

  const _SwitchWithTime({
    required this.dark,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.timeLabel,
    required this.hour,
    required this.minute,
    required this.onTapTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NotificationSwitch(
          dark: dark,
          title: title,
          subtitle: subtitle,
          value: value,
          onChanged: onChanged,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: value
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: DeenColors.dividerLine(dark),
                    ),
                    AccountRow(
                      icon: Icons.schedule_rounded,
                      label: timeLabel,
                      dark: dark,
                      trailingText:
                          TimeOfDay(hour: hour, minute: minute).format(context),
                      showChevron: true,
                      onTap: onTapTime,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
