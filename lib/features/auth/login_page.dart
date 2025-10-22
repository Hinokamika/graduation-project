import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/auth_service.dart';
import 'package:final_project/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_page.dart';
import 'package:final_project/features/auth/signup_page.dart';

class LoginPage extends StatefulWidget {
  final bool returnOnSuccess;
  const LoginPage({super.key, this.returnOnSuccess = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Mark onboarding as complete and sync any local survey to Supabase
      final userService = UserService();
      await userService.markOnboardingComplete();
      await userService.syncLocalSurveyToSupabase();

      if (!mounted) return;
      if (widget.returnOnSuccess) {
        Navigator.of(context).pop(true);
      } else {
        // Navigate to home page on successful login
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Welcome Back', style: AppTextStyles.heading3),
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 24),

              // Email Input Label
              Text('Email Address', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r"\s")),
                ],
                enabled: !_isLoading,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: 'Enter your email address',
                  hintStyle: AppTextStyles.hint,
                  // Use themed fill from InputDecorationTheme
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 13.0),
                    child: const FaIcon(
                      FontAwesomeIcons.envelope,
                      color: AppColors.textLight,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return 'Please enter your email';
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(v))
                    return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password Input Label
              Text('Password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                enabled: !_isLoading,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: AppTextStyles.hint,
                  // Use themed fill from InputDecorationTheme
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 13.0),
                    child: const FaIcon(
                      FontAwesomeIcons.lock,
                      color: AppColors.textLight,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Forgot Password
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () => _forgotPassword(),
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
                    'Forgot Password?',
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sign Up Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SignUpPage(
                              returnToPreviousOnSuccess: widget.returnOnSuccess,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ResetPasswordPage()));
  }
}
