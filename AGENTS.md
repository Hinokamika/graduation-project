# Repository Guidelines

## Project Structure & Module Organization
- Entry point: `lib/main.dart`.
- Organize `lib/` by responsibility:
  - `config/` app-wide config (e.g., `app_config.dart`).
  - `features/` feature-first pages (e.g., `features/auth/login_page.dart`).
  - `services/` side effects/APIs (e.g., `auth_service.dart`, `user_service.dart`).
  - `utils/` shared constants/helpers (e.g., `app_colors.dart`, `text_styles.dart`).
  - `widgets/` reusable UI (e.g., `auth_wrapper.dart`).
- Platforms: `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`.
- Tests live in `test/` mirroring `lib/`; design docs in `DESIGN_SYSTEM.md`.

## Build, Test, and Development Commands
- `flutter pub get` — fetches packages.
- `flutter run` (web: `flutter run -d chrome`) — run locally.
- `flutter analyze` — static analysis; fix all warnings before PR.
- `dart format .` — apply Dart formatting across the repo.
- `flutter test` — execute unit/widget tests.
- `flutter build apk|ios|web` — production builds.

## Coding Style & Naming Conventions
- Dart style with 2-space indent, null safety, small composable widgets.
- Naming: Classes `UpperCamelCase`; methods/vars `lowerCamelCase`; files `snake_case.dart`.
- File patterns: pages end with `_page.dart`; services with `_service.dart`.
- Linting via `flutter_lints` and `analysis_options.yaml`. Prefer `const`; avoid oversized widgets.

## Testing Guidelines
- Framework: `flutter_test`.
- Place tests in `test/` using `*_test.dart` mirroring `lib/` structure.
- Prioritize widget tests for pages and unit tests for services/utils.
- Cover critical flows (auth, navigation, profile). Run `flutter test` before PR.

## Commit & Pull Request Guidelines
- Use Conventional Commits (e.g., `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`). Keep changes small and focused.
- PRs include: clear description, linked issues, screenshots/GIFs for UI changes, and test notes.
- Update docs when behavior changes.

## Security & Configuration Tips
- Never commit secrets. Use `.env` with `flutter_dotenv`.
- Supabase: set `SUPABASE_URL` and `SUPABASE_ANON_KEY` (loaded in `main.dart`).
- For web, whitelist local/dev domains in Supabase Auth (e.g., `http://localhost:xxxx`).

## Agent-Specific Instructions
- Keep patches minimal and scoped; follow structure/naming above.
- Avoid unrelated refactors. Run `flutter analyze` and `flutter test` before requesting review.

