# Repository Guidelines

## Project Structure & Module Organization
- Entry point: `lib/main.dart`
- App code: `lib/` organized by responsibility
  - `config/` app-wide config (e.g., `app_config.dart`)
  - `pages/` screen widgets (e.g., `login_page.dart`, `home_page.dart`)
  - `services/` side effects and APIs (e.g., `auth_service.dart`)
  - `utils/` shared constants/helpers (e.g., `app_colors.dart`)
  - `widgets/` reusable UI pieces (e.g., `auth_wrapper.dart`)
- Platform folders: `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`
- Firebase: `lib/firebase_options.dart` (generated), config in `.env` (declared in `pubspec.yaml`)

## Build, Test, and Development Commands
- Install deps: `flutter pub get`
- Run app: `flutter run` (e.g., web: `flutter run -d chrome`)
- Analyze lints: `flutter analyze`
- Format code: `dart format .`
- Run tests: `flutter test`
- Build releases: `flutter build apk | ios | web`

## Coding Style & Naming Conventions
- Follow Dart style (2-space indent, null safety).
- Names: Classes `UpperCamelCase`, methods/vars `lowerCamelCase`, files `snake_case.dart`.
- Directory patterns: pages end with `_page.dart`, services with `_service.dart`.
- Prefer `const` widgets where possible; keep widgets small and composable.
- Linting via `flutter_lints` and `analysis_options.yaml`; fix all analyzer warnings.

## Testing Guidelines
- Framework: `flutter_test`.
- Location: create tests under `test/` with `*_test.dart` names.
- Focus: widget tests for pages and unit tests for services/utils.
- Run locally with `flutter test`; aim for meaningful coverage on critical flows (auth, navigation).

## Commit & Pull Request Guidelines
- Use Conventional Commits: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`. Write short, imperative messages.
- PRs should include: clear description, linked issues, screenshots/GIFs for UI changes, and test notes.
- Keep PRs focused and small; update any doc references (e.g., `DESIGN_SYSTEM.md`).

## Security & Configuration Tips
- Secrets: never commit real credentials; use `.env` with `flutter_dotenv`.
- Ensure Firebase project setup matches `lib/firebase_options.dart`; update via the FlutterFire CLI when environments change.
- For web, whitelist auth domains in Firebase console before testing `-d chrome`.

