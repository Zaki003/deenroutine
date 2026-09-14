import '../l10n/app_localizations.dart';
import '../providers/learn_provider.dart';

/// Maps a [LearnErrorType] to a localized message.
String learnErrorMessage(AppLocalizations l10n, LearnErrorType type, String? detail) {
  switch (type) {
    case LearnErrorType.syncFailed:
      return l10n.learnSyncError;
    case LearnErrorType.saveFailed:
      return l10n.learnSaveFailed;
  }
}
