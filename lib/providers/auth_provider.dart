import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  static const _deviceAccountCountKey = 'device_account_count';

  /// Registration doesn't verify email addresses, so nothing but this stops
  /// someone from creating accounts indefinitely on one device - each is a
  /// real Firebase Auth user plus a Firestore doc, chipping away at the free
  /// tier for no reason. Deliberately device-local (SharedPreferences, not
  /// Firestore, mirroring [ThemeProvider]'s reasoning): it only has to stop
  /// casual repeat taps, not survive a deliberate reinstall, and it must
  /// never sync across devices or it'd cap the whole userbase together.
  static const maxAccountsPerDevice = 3;

  User? _firebaseUser;
  AppUser? _appUser;
  bool _loading = false;
  String? _errorCode;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _loading;

  /// A [FirebaseAuthException.code] (e.g. `'wrong-password'`), not a
  /// display string — map it through `authErrorMessage` before showing it.
  String? get errorCode => _errorCode;
  bool get isLoggedIn => _firebaseUser != null;

  /// True from a successful [register] until [finishOnboarding] is called.
  /// _AuthGate checks this alongside [isLoggedIn] so MainNavScreen doesn't
  /// mount (hidden, underneath the onboarding screens) the instant
  /// [authStateChanges] fires — it would otherwise fire location/notification
  /// requests itself before onboarding gets to prime the user for them.
  bool _inOnboarding = false;
  bool get inOnboarding => _inOnboarding;

  void finishOnboarding() {
    _inOnboarding = false;
    notifyListeners();
  }

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _appUser = await _authService.getUserProfile(user.uid);
    } else {
      _appUser = null;
    }
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_deviceAccountCountKey) ?? 0;
      if (count >= maxAccountsPerDevice) {
        _errorCode = 'device-account-limit';
        return false;
      }
      _appUser = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      await prefs.setInt(_deviceAccountCountKey, count + 1);
      _errorCode = null;
      _inOnboarding = true;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.login(email: email, password: password);
      _errorCode = null;
      // Defensive: a fresh login must never stay blocked by a previously
      // abandoned registration's leftover flag (e.g. backed out of
      // onboarding to LoginScreen without finishing).
      _inOnboarding = false;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() => _authService.logout();

  /// Sends a password-reset email. Deliberately reports success even for
  /// 'user-not-found': Firebase's email-enumeration protection already hides
  /// this distinction on sign-in (see 'invalid-credential' in
  /// auth_error_messages.dart), so surfacing "no account with that email"
  /// here would reopen the exact leak that protection exists to close.
  /// Genuine problems (rate limiting, network) still surface normally.
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
      _errorCode = null;
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorCode = null;
        return true;
      }
      _errorCode = e.code;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clears a leftover error from whichever auth screen the user was just
  /// on (e.g. a failed login shouldn't still be showing once they tap
  /// through to Register or Forgot Password). No notifyListeners() - this
  /// is meant to be called from a fresh screen's initState, before that
  /// screen's own first build, so nothing needs to be told to rebuild.
  void clearError() {
    _errorCode = null;
  }

  /// Play Store data-deletion requirement: re-authenticates with [password],
  /// then permanently deletes the signed-in user's Firestore data and
  /// Firebase Auth account. Mirrors [login]/[register]'s _setLoading/
  /// errorCode shape.
  ///
  /// No explicit navigation here — deleting the Firebase Auth user tears
  /// down the local session itself, which fires [authStateChanges] with a
  /// null user, the same mechanism [logout] relies on to flip the app back
  /// to LoginScreen.
  Future<bool> deleteAccount(String password) async {
    _setLoading(true);
    try {
      await _authService.deleteAccount(password);
      _errorCode = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// FR-03: Profile management. Only the fields passed are updated — see
  /// [AuthService.updateProfile]. `_errorCode` on failure won't match any
  /// [FirebaseAuthException] code, so `authErrorMessage` falls through to
  /// its generic message, same as an unrecognized code always has.
  Future<bool> updateProfile({String? name, AvatarOption? avatar}) async {
    if (_appUser == null) return false;
    _setLoading(true);
    try {
      await _authService.updateProfile(uid: _appUser!.uid, name: name, avatar: avatar);
      _appUser = _appUser!.copyWith(name: name, avatar: avatar);
      _errorCode = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorCode = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
