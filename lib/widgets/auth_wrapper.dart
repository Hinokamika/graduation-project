import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_project/pages/survey_page.dart';
import 'package:final_project/pages/auth_options_page.dart';
import 'package:final_project/pages/intro_page.dart';
import 'package:final_project/pages/home_page.dart';
import 'package:final_project/services/user_service.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isOnboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _checkUserState();
  }

  Future<void> _checkUserState() async {
    // Listen to Supabase auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _isAuthenticated = session != null;
      });

      if (_isAuthenticated) {
        // When authenticated, we go straight to Home
        setState(() {
          _isOnboardingComplete = true;
          _isLoading = false;
        });
      } else {
        // Not authenticated
        setState(() {
          _isOnboardingComplete = false;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
              SizedBox(height: 24),
              Text('Loading...', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    // User Flow Logic:
    // - Not authenticated → IntroPage (always)
    // - Authenticated → HomePage

    if (!_isAuthenticated) {
      return const IntroPage();
    }

    return const HomePage();

    // Fallback loading state
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
            SizedBox(height: 24),
            Text('Loading...', style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
