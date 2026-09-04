import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'firestore_service.dart';

/// FR-01 / FR-02: Registration and Login
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final appUser = AppUser(uid: uid, name: name, email: email);
    await _db.collection('Users').doc(uid).set(appUser.toMap());

    await credential.user!.updateDisplayName(name);
    return appUser;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// FR-03: Profile management. Only the fields passed are touched — a
  /// name-only change doesn't overwrite the avatar, and vice versa. Keeps
  /// Firebase Auth's displayName in sync with Firestore's name field, the
  /// same pair [register] writes to.
  Future<void> updateProfile({required String uid, String? name, AvatarOption? avatar}) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar.name,
    };
    if (updates.isNotEmpty) {
      await _db.collection('Users').doc(uid).update(updates);
    }
    if (name != null) {
      await _auth.currentUser?.updateDisplayName(name);
    }
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection('Users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  /// Re-authenticates the signed-in user with their password — Firebase Auth
  /// requires a fresh session for security-sensitive ops like [deleteAccount].
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'user-mismatch');
    }
    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  /// Play Store data-deletion requirement. Wipes all Firestore data via
  /// [FirestoreService.deleteAllUserData], then deletes the Firebase Auth
  /// user. Irreversible. Always reauthenticates first — a stale session
  /// makes the final `user.delete()` throw `requires-recent-login` anyway,
  /// so checking here means the Firestore wipe never fires on a doomed
  /// attempt. Ordering after that matters: the wipe must finish while the
  /// uid is still `request.auth.uid`, so it runs before `user.delete()`.
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-mismatch');
    await reauthenticate(password);
    await _firestoreService.deleteAllUserData(user.uid);
    await user.delete();
  }
}
