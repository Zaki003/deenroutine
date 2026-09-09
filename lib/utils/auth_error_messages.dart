import '../l10n/app_localizations.dart';

/// Maps a [FirebaseAuthException.code] (plus one synthetic app-level code,
/// `device-account-limit`, that never reaches Firebase) to a localized
/// message. Firebase's own `.message` is English-only prose, so
/// [AuthProvider] stores the stable `.code` instead and this does the
/// (localizable) translation.
String authErrorMessage(AppLocalizations l10n, String? code) {
  switch (code) {
    case 'wrong-password':
      return l10n.authErrorWrongPassword;
    case 'invalid-credential':
      // Firebase returns this (instead of 'wrong-password'/'user-not-found')
      // when email enumeration protection is on, so a non-existent account
      // and a wrong password are indistinguishable here by design.
      return l10n.authErrorInvalidCredential;
    case 'user-not-found':
      return l10n.authErrorUserNotFound;
    case 'invalid-email':
      return l10n.authErrorInvalidEmail;
    case 'email-already-in-use':
      return l10n.authErrorEmailInUse;
    case 'weak-password':
      return l10n.authErrorWeakPassword;
    case 'requires-recent-login':
      return l10n.authErrorRequiresRecentLogin;
    case 'too-many-requests':
      return l10n.authErrorTooManyRequests;
    case 'device-account-limit':
      // Not a FirebaseAuthException code - synthesized by AuthProvider.register
      // before it ever calls Firebase, see the doc comment there.
      return l10n.authErrorDeviceLimit;
    default:
      return l10n.authErrorGeneric;
  }
}
