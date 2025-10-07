import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthOptionsPage extends StatelessWidget {
  const AuthOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: Theme.of(context).colorScheme.onSurface,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Small banner if survey is completed but user not logged in
              FutureBuilder<bool>(
                future: _shouldShowOnboardingBanner(),
                builder: (context, snapshot) {
                  final show = snapshot.data == true;
                  if (!show) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.circleCheck,
                          color: AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your profile info is saved. Sign in or create an account to continue.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),

              // Welcome back message
              Text('Welcome to', style: AppTextStyles.heading3),
              const SizedBox(height: 8),

              Text('Healthcare+', style: AppTextStyles.heading1),
              const SizedBox(height: 16),

              Text(
                'Continue your health journey',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/signup');
                  },
                  child: Text(
                    'Create Account',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    backgroundColor: Theme.of(context).cardColor,
                    side: BorderSide(color: AppColors.accent, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: Text(
                    'Sign In',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Privacy note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _shouldShowOnboardingBanner() async {
  final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
  if (isLoggedIn) return false;
  final completed = await UserService().isOnboardingComplete();
  return completed;
}
