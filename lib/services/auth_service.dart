import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authServiceProvider = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteUser() async {
    User? user = firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  Future<void> updateUsername({required String username}) async {
    User? user = firebaseAuth.currentUser;
    if (user != null) {
      await user.updateProfile(displayName: username);
      await user.reload();
    }
  }

  Future<void> updateEmail({required String email}) async {
    User? user = firebaseAuth.currentUser;
    if (user != null) {
      await user.verifyBeforeUpdateEmail(email);
      await user.reload();
    }
  }

  Future<void> updatePassword({required String password}) async {
    User? user = firebaseAuth.currentUser;
    if (user != null) {
      await user.updatePassword(password);
      await user.reload();
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    User? user = firebaseAuth.currentUser;
    if (user != null) {
      // Re-authenticate the user before deleting the account
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.delete();
      await signOut();
    }
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    User? user = firebaseAuth.currentUser;
    if (user != null) {
      // Re-authenticate the user before updating the password
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      await user.reload();
    }
  }
}
