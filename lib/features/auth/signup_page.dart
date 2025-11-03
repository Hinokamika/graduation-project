import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/auth_service.dart';
import 'package:final_project/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignUpPage extends StatefulWidget {
  final bool returnToPreviousOnSuccess;
  const SignUpPage({super.key, this.returnToPreviousOnSuccess = false});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user account with metadata to avoid requiring an active session
      await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );

      // Fire-and-forget: profile bootstrap/sync should not block signup UX
      // It will also run again after the first login.
      unawaited(Future(() async {
        try {
          final userService = UserService();
          await userService.createOrUpdateUserIdentityFromSignup(
            email: _emailController.text.trim(),
            userName: _nameController.text.trim(),
          );
          await userService.syncLocalSurveyToSupabase();
        } catch (_) {}
      }));

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please login.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to login with proper return behavior (don’t wait for background sync)
        if (widget.returnToPreviousOnSuccess) {
          // Return to the previous screen (typically Login)
          Navigator.of(context).pop();
        } else {
          // Stronger navigation to avoid being stuck on SignUp route
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
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
        title: Text('Create Account', style: AppTextStyles.heading3),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 13.0),
                    child: FaIcon(FontAwesomeIcons.user),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(
                    RegExp(r"\s"),
                  ), // prevent spaces/newlines
                ],
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13.0, vertical: 13.0),
                    child: FaIcon(FontAwesomeIcons.envelope),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13.0, vertical: 13.0),
                    child: FaIcon(FontAwesomeIcons.lock),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13.0, vertical: 13.0),
                    child: FaIcon(FontAwesomeIcons.lock),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Sign Up',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (widget.returnToPreviousOnSuccess) {
                    // If we came from a return-on-success login, just go back to it
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushNamed('/login');
                  }
                },
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(color: primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
