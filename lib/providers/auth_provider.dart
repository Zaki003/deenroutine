import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

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
      _appUser = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _errorCode = null;
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
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() => _authService.logout();

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

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
