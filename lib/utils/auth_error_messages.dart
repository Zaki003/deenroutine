import '../l10n/app_localizations.dart';

/// Maps a [FirebaseAuthException.code] to a localized message. Firebase's
/// own `.message` is English-only prose, so [AuthProvider] stores the
/// stable `.code` instead and this does the (localizable) translation.
String authErrorMessage(AppLocalizations l10n, String? code) {
  switch (code) {
    case 'wrong-password':
    case 'invalid-credential':
      return l10n.authErrorWrongPassword;
    case 'user-not-found':
      return l10n.authErrorUserNotFound;
    case 'invalid-email':
      return l10n.authErrorInvalidEmail;
    case 'email-already-in-use':
      return l10n.authErrorEmailInUse;
    case 'weak-password':
      return l10n.authErrorWeakPassword;
    default:
      return l10n.authErrorGeneric;
  }
}
