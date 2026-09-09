import '../l10n/app_localizations.dart';
import '../services/prayer_service.dart';

/// Whether [type] can only be fixed via a system Settings screen, not by
/// retrying inside the app. Android never re-shows the permission dialog
/// once denied "forever" (see [PrayerService.openAppSettings]), and a
/// disabled location service isn't an app-permission problem at all — for
/// both, wiring the UI's action button to another [loadPrayerTimes] retry
/// would just fail identically every time instead of doing anything useful.
bool prayerErrorNeedsSettings(PrayerErrorType type) =>
    type == PrayerErrorType.permissionDeniedForever ||
    type == PrayerErrorType.locationServicesDisabled;

String prayerErrorMessage(AppLocalizations l10n, PrayerErrorType type, String? detail) {
  switch (type) {
    case PrayerErrorType.locationServicesDisabled:
      return l10n.prayerErrorLocationDisabled;
    case PrayerErrorType.permissionDenied:
      return l10n.prayerErrorPermissionDenied;
    case PrayerErrorType.permissionDeniedForever:
      return l10n.prayerErrorPermissionDeniedForever;
    case PrayerErrorType.fetchFailed:
      return l10n.prayerErrorFetchFailed(detail ?? '');
    case PrayerErrorType.unknown:
      return l10n.prayerErrorUnknown;
  }
}
