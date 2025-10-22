import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Banner variants depending on onboarding state when not logged in
              // 1) Onboarding complete → prompt to continue to Auth Options
              FutureBuilder<bool>(
                future: _shouldShowOnboardingBanner(),
                builder: (context, snapshot) {
                  final show = snapshot.data == true;
                  if (!show) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                          FontAwesomeIcons.circleInfo,
                          color: AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your health profile is saved. Create an account or sign in to sync.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/auth_options'),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // 2) Onboarding not complete → prompt to go to Survey
              FutureBuilder<bool>(
                future: _shouldShowSurveyLinkBanner(),
                builder: (context, snapshot) {
                  final show = snapshot.data == true;
                  if (!show) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.clipboard,
                          color: AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You haven't finished your health profile yet.",
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/survey'),
                          child: const Text('Go to Survey'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // App Icon/Logo
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 35.0),
                  child: const FaIcon(
                    FontAwesomeIcons.solidHeart,
                    size: 40,
                    color: AppColors.accent,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App Title
              Text('Healthcare+', style: AppTextStyles.heading1),

              const SizedBox(height: 16),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Your personalized journey to better health starts here. Track, monitor, and improve your wellness with our comprehensive healthcare platform.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Get Started Button
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
                    Navigator.of(context).pushNamed('/survey');
                  },
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Already have account
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/auth_options');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                child: Text(
                  'Already have an account?',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),

              const SizedBox(height: 16),
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

Future<bool> _shouldShowSurveyLinkBanner() async {
  final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
  if (isLoggedIn) return false;
  final completed = await UserService().isOnboardingComplete();
  return !completed;
}
