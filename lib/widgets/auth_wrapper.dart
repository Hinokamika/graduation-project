import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_project/features/onboarding/intro_page.dart';
import 'package:final_project/features/home/home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // If session recovery fails (e.g., invalid refresh token),
          // fall back to unauthenticated flow instead of crashing.
          return const IntroPage();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const HomePage();
        }
        return const IntroPage();
      },
    );
  }
}
