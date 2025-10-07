import 'package:final_project/features/chat/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:final_project/features/onboarding/intro_page.dart';
import 'package:final_project/features/auth/auth_options_page.dart';
import 'package:final_project/features/auth/signup_page.dart';
import 'package:final_project/features/auth/login_page.dart';
import 'package:final_project/features/onboarding/survey_page.dart';
import 'package:final_project/features/home/home_page.dart';
import 'package:final_project/features/profile/user_page.dart';
import 'package:final_project/features/settings/settings_page.dart';
import 'package:final_project/widgets/auth_wrapper.dart';
import 'package:final_project/config/app_theme.dart';
import 'package:final_project/config/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:final_project/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:final_project/features/habit/history_page.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Default Supabase configuration
      String supabaseUrl = '';
      String supabaseAnonKey = '';

      try {
        // Try to load environment variables (for development)
        await dotenv.load(fileName: ".env");
        // Override with env values if available
        supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      } catch (e) {
        // Using default config values (env file not found)
        // In production, consider using a proper logging framework
        debugPrint('Using default config values (env file not found): $e');
      }

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        debugPrint(
          '[Config] Missing SUPABASE_URL or SUPABASE_ANON_KEY. Check your .env.',
        );
      }

      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

      // Start background sync for offline -> online transitions
      await UserService().startSyncListeners();
      // Ask for Apple Health permissions on first launch (iOS only)
      await UserService().requestHealthPermissionsAtFirstLaunch();
      // Debug: print Hive box info at startup in debug builds
      if (kDebugMode) {
        await UserService().debugPrintHiveInfo();
      }
      runApp(const MyApp());
    },
    (error, stack) async {
      // Handle Supabase recoverSession failures gracefully (e.g., invalid refresh token)
      final msg = error.toString();
      final looksLikeRefreshTokenError =
          msg.contains('refresh_token_not_found') ||
          msg.contains('Invalid Refresh Token');
      if (looksLikeRefreshTokenError) {
        debugPrint(
          '[Auth] Invalid/expired refresh token. Clearing local session.',
        );
        try {
          // Clear only local session to avoid network dependency
          await Supabase.instance.client.auth.signOut(
            scope: SignOutScope.local,
          );
        } catch (_) {
          // Ignore secondary errors
        }
      } else {
        debugPrint('Unhandled error: $error');
        debugPrint(stack.toString());
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'HealthCare+ App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/intro': (context) => const IntroPage(),
            '/survey': (context) => const SurveyPage(),
            '/auth_options': (context) => const AuthOptionsPage(),
            '/signup': (context) => const SignUpPage(),
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
            '/user': (context) => const UserPage(),
            '/settings': (context) => const SettingsPage(),
            '/chat': (context) => const ChatPage(),
            '/habit_history': (context) => const HabitHistoryPage(),
          },
        );
      },
    );
  }
}
