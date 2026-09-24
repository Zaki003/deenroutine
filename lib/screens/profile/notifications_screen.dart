import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/notification_settings_provider.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/account_row.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/section_label.dart';

/// Where the notification choices live: the daily ayah/hadith (on/off and
/// time), plus whether the phone is actually allowing the app's reminders
/// through - the usual reason a reminder never shows up, and otherwise
/// something only visible deep in system settings.
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

  Future<void> _pickTime(NotificationSettingsProvider settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: settings.quoteHour, minute: settings.quoteMinute),
    );
    if (picked != null) await settings.setQuoteTime(picked.hour, picked.minute);
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

    final noteStyle =
        TextStyle(fontSize: 11.5, height: 1.4, color: DeenColors.textMuted(dark));
    // On: gold on dark, teal on light - DeenColors.primary alone vanishes into
    // the dark card. Off: the muted track/thumb the rest of the UI uses.
    final onTrack = dark ? DeenColors.gold : DeenColors.primary;
    final onThumb = dark ? DeenColors.ink : Colors.white;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.dailyQuoteNotifyTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DeenColors.primaryText(dark),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(l10n.dailyQuoteNotifySubtitle, style: noteStyle),
                    ),
                    value: settings.quoteEnabled,
                    onChanged: settings.loaded ? settings.setQuoteEnabled : null,
                    thumbColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                            ? onThumb
                            : DeenColors.textMuted(dark)),
                    trackColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                            ? onTrack
                            : DeenColors.trackLine(dark)),
                    trackOutlineColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? Colors.transparent
                            : DeenColors.outlineFaint(dark)),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: settings.quoteEnabled
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
                                label: l10n.dailyQuoteNotifyTimeLabel,
                                dark: dark,
                                trailingText: TimeOfDay(
                                  hour: settings.quoteHour,
                                  minute: settings.quoteMinute,
                                ).format(context),
                                showChevron: true,
                                onTap: () => _pickTime(settings),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(l10n.dailyQuoteNotifyFootnote, style: noteStyle),
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
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: DeenColors.dividerLine(dark)),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(l10n.notificationsProblemNote, style: noteStyle),
              ),
          ],
        ),
      ),
    );
  }
}
