import '../l10n/app_localizations.dart';
import '../providers/habit_provider.dart';

String habitErrorMessage(AppLocalizations l10n, HabitErrorType type, String? detail) {
  final d = detail ?? '';
  switch (type) {
    case HabitErrorType.syncFailed:
      return l10n.habitSyncError(d);
    case HabitErrorType.duplicateTitle:
      return l10n.habitDuplicateTitle(d);
    case HabitErrorType.updateFailed:
      return l10n.habitUpdateFailed(d);
    case HabitErrorType.deleteFailed:
      return l10n.habitDeleteFailed(d);
  }
}
