import 'package:flutter/material.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/pages/intro_page.dart';
import 'package:final_project/pages/auth_options_page.dart';
import 'package:final_project/pages/signup_page.dart';
import 'package:final_project/pages/login_page.dart';
import 'package:final_project/pages/survey_page.dart';
import 'package:final_project/pages/home_page.dart';
import 'package:final_project/pages/user_page.dart';
import 'package:final_project/pages/settings_page.dart';
import 'package:final_project/widgets/auth_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
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

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthCare+ App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: lightPeach,
        primaryColor: primaryBlue,
        fontFamily: 'SF Pro Display', // Clean, modern font
        colorScheme: ColorScheme.light(
          primary: primaryBlue,
          secondary: secondaryBlue,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          surface: lightPeach,
          onSurface: black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryBlue,
            side: const BorderSide(color: primaryBlue, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: black),
          titleTextStyle: TextStyle(color: black, fontSize: 20),
        ),
      ),
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
      },
    );
  }
}
