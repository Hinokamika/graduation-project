import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

ValueNotifier<AuthService> authServiceProvider = ValueNotifier(AuthService());

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<Session?> get authStateChanges => _supabase.auth.onAuthStateChange.map((event) => event.session);

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null && fullName.trim().isNotEmpty
          ? {'full_name': fullName.trim()}
          : null,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  Future<void> updateUsername({required String username}) async {
    await _supabase.auth.updateUser(UserAttributes(data: {'full_name': username}));
  }

  Future<void> updateEmail({required String email}) async {
    await _supabase.auth.updateUser(UserAttributes(email: email));
  }

  Future<void> updatePassword({required String password}) async {
    await _supabase.auth.updateUser(UserAttributes(password: password));
  }
}
