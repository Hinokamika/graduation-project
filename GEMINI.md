# Gemini Code Assistant Context

## Project Overview

This is a Flutter project for a healthcare application named "HealthCare+". It appears to be in the early stages of development. The application allows users to create an account, fill out a health survey, and log in. It is integrated with Firebase and Supabase for backend services.

**Technologies:**

*   **Framework:** Flutter
*   **Language:** Dart
*   **Backend:** Firebase, Supabase
*   **Environment Variables:** `flutter_dotenv`

## Building and Running

To run the application, use the following command in your terminal:

```bash
flutter run
```

To run tests, use:

```bash
flutter test
```

## Development Conventions

*   **Linting:** The project uses the default linting rules provided by the `flutter_lints` package. The configuration can be found in `analysis_options.yaml`.
*   **Style:** The code follows the standard Dart and Flutter style guides. The UI seems to have a consistent theme defined in `lib/main.dart` and `lib/utils/app_colors.dart`.
*   **Routing:** The application uses named routes for navigation, which are defined in `lib/main.dart`.

## Key Files

*   `pubspec.yaml`: The project's configuration file. It defines the project's dependencies, version, and other metadata.
*   `lib/main.dart`: The main entry point of the application. It initializes Firebase and Supabase, and defines the application's routes and theme.
*   `lib/pages/intro_page.dart`: The first page the user sees, which provides an introduction to the app.
*   `lib/pages/survey_page.dart`: A page that collects health information from the user.
*   `lib/pages/auth_options_page.dart`: A page that gives the user the option to sign up or log in.
*   `lib/pages/signup_page.dart`: The user registration page.
*   `lib/pages/login_page.dart`: The user login page.
*   `.env`: This file (not checked into version control) is used to store environment variables such as Supabase URL and anonymous key.

## Directory Overview

*   `lib/`: Contains the main Dart source code for the application.
*   `lib/pages/`: Contains the different pages or screens of the application.
*   `lib/utils/`: Contains utility files, such as `app_colors.dart`.
*   `android/`: Contains the Android-specific project files.
*   `ios/`: Contains the iOS-specific project files.
*   `web/`: Contains the web-specific project files.
*   `test/`: Contains the tests for the application.
