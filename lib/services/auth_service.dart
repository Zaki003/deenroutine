import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// FR-01 / FR-02: Registration and Login
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  /// FR-03: Profile management
  Future<void> updateProfile({required String uid, required String name}) {
    return _db.collection('Users').doc(uid).update({'name': name});
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection('Users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }
}
