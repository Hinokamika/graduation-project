# Repository Guidelines

## Project Structure & Module Organization
- Entry point: `lib/main.dart`.
- App code under `lib/` by responsibility:
  - `config/` app-wide config (e.g., `app_config.dart`)
  - `features/` feature-first screens (e.g., `features/auth/login_page.dart`, `features/home/home_page.dart`, `features/profile/user_page.dart`)
  - `services/` side effects/APIs (e.g., `auth_service.dart`, `user_service.dart`)
  - `utils/` shared constants/helpers (e.g., `app_colors.dart`, `text_styles.dart`)
  - `widgets/` reusable UI pieces (e.g., `auth_wrapper.dart`)
- Platform folders: `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`.
- Tests in `test/` with `*_test.dart`. Design docs: `DESIGN_SYSTEM.md`.

## Build, Test, and Development Commands
- Install deps: `flutter pub get` — fetches packages.
- Run app: `flutter run` (web: `flutter run -d chrome`).
- Analyze lints: `flutter analyze` — fix all warnings.
- Format code: `dart format .` — apply Dart style.
- Run tests: `flutter test` — executes widget/unit tests.
- Build releases: `flutter build apk | ios | web`.

## Coding Style & Naming Conventions
- Dart style: 2-space indent, null safety, small composable widgets.
- Naming: Classes `UpperCamelCase`; methods/vars `lowerCamelCase`; files `snake_case.dart`.
- File patterns: pages end with `_page.dart`, services with `_service.dart`.
- Linting via `flutter_lints` and `analysis_options.yaml`. Prefer `const`, avoid large widgets.

## Testing Guidelines
- Framework: `flutter_test`.
- Place tests in `test/` using `*_test.dart` mirroring `lib/` structure.
- Focus on widget tests for pages and unit tests for services/utils.
- Run `flutter test`; prioritize auth, navigation, and profile flows.

## Commit & Pull Request Guidelines
- Use Conventional Commits (e.g., `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`).
- Keep commits and PRs small and focused; imperative tense.
- PRs include a clear description, linked issues, screenshots/GIFs for UI changes, and test notes. Update docs when behavior changes.

## Security & Configuration Tips
- Do not commit secrets. Use `.env` with `flutter_dotenv`.
- Supabase: set `SUPABASE_URL` and `SUPABASE_ANON_KEY` (loaded in `main.dart`).
- For web, whitelist local/dev domains in Supabase Auth (e.g., `http://localhost:xxxx`).

