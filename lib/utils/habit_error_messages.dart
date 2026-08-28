import '../l10n/app_localizations.dart';
import '../providers/habit_provider.dart';

/// Maps a [HabitErrorType] to a localized message. Only [duplicateTitle]'s
/// [detail] is shown to the user (it's the habit title they typed) — the
/// other cases carry a raw [Exception.toString]() in [detail], which isn't
/// meaningful to someone using the app, so their copy is a fixed friendly
/// sentence instead of interpolating it.
String habitErrorMessage(AppLocalizations l10n, HabitErrorType type, String? detail) {
  switch (type) {
    case HabitErrorType.syncFailed:
      return l10n.habitSyncError;
    case HabitErrorType.duplicateTitle:
      return l10n.habitDuplicateTitle(detail ?? '');
    case HabitErrorType.updateFailed:
      return l10n.habitUpdateFailed;
    case HabitErrorType.deleteFailed:
      return l10n.habitDeleteFailed;
  }
}
