import '../l10n/app_localizations.dart';
import '../utils/prayer_check_in_plan.dart';
import 'notification_service.dart';

/// Applies a [CheckInPlan]: schedules each planned check-in (replacing any
/// pending one with the same ID) and cancels every other ID in the check-in
/// band, except [CheckInPlan.keepIds] - so a prayer logged in the app loses
/// its check-in, including one already on screen, while a "Later" repeat for
/// a prayer that's still open survives.
class PrayerCheckInScheduler {
  final NotificationService _notifications;

  PrayerCheckInScheduler(this._notifications);

  Future<void> apply(CheckInPlan plan, AppLocalizations l10n, {required bool Function() isCurrent}) async {
    final wanted = plan.wantedIds;
    final stale = [
      for (var i = 0; i < prayerCheckInSlots; i++)
        if (!wanted.contains(prayerCheckInIdBase + i)) prayerCheckInIdBase + i,
    ];
    await _notifications.cancelIds(stale);
    for (final checkIn in plan.checkIns) {
      if (!isCurrent()) return;
      await _notifications.scheduleCheckIn(
        id: checkIn.id,
        when: checkIn.when,
        payload: checkIn.payload,
        prayedLabel: l10n.prayerCheckInPrayed,
        laterLabel: l10n.prayerCheckInLater,
      );
    }
  }

  Future<void> cancelAll() => _notifications.cancelCheckIns();
}
