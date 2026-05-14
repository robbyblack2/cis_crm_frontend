---
name: configure-flutter-app
description: Idempotent end-to-end setup of a Flutter project against the flutter-bloc-architect skill. Asks the user for app name, bundle ID prefix, flavors, and target platforms, then writes pubspec.yaml, analysis_options.yaml, lib/ scaffold, l10n files, Makefile, .vscode/launch.json, lefthook.yml, and CI workflow. Generates launcher icon + native splash. Smoke-tests with analyze + test + per-platform builds.
---

# /configure-flutter-app

Bootstraps an empty (or freshly `flutter create`d) project into the locked architecture defined by this skill. Idempotent — safe to re-run on a partially-configured project.

**TDD is enforced from the first feature.** Once configuration finishes and the user starts adding features, every new bloc / repo / data source / page is built red-green-refactor (write failing test, write minimum impl, refactor). The `feature-scaffolder` agent emits failing tests alongside minimum stubs; running `flutter test` immediately after scaffolding produces a meaningful red bar that the user fills in green. See `references/testing.md` and the user's overall `tdd` skill.

## Preconditions

1. **Flutter SDK ≥ 3.24.** Bail with a clear error otherwise.
2. **Working directory has a `pubspec.yaml`.** If not, the slash command offers to run `flutter create <name> --org <reverse-domain> --platforms <comma-separated>` after collecting the prompts in step 1 below; otherwise it bails.
3. **Git status is clean** OR the user explicitly confirms running on a dirty tree.

## Step 1 — Interactive prompts (one at a time)

1. **App display name** (e.g., "Acme Notes").
2. **Bundle ID / package prefix** — show `com.example.<app>` as a placeholder; do NOT assume any prefix.
3. **Flavor scheme:**
   - `dev | prod` (default — press enter to accept)
   - `dev | staging | prod`
   - custom (user types names comma-separated)
4. **Default flavor** — defaults to `prod`. The chosen value becomes `defaultValue:` in `String.fromEnvironment('FLAVOR', defaultValue: '<this>')`.
5. **Target platforms** — checklist: Android, iOS, web, macOS, Windows, Linux. Default = all six.
6. **Launcher icon source PNG** — absolute path; or "skip" to auto-generate a placeholder.
7. **Theme seed color** — hex, default `#6750A4` (Material 3's default). Used for `ColorScheme.fromSeed`, the placeholder icon background, and the splash background.
8. **Optional features** (checklist):
   - Sentry crash reporting
   - Firebase Analytics
   - Connectivity awareness
   - Feature flags (Firebase Remote Config)
   - Push notifications (Firebase Messaging)
   - Deep links (`app_links`)
   - Force-upgrade flow

Echo all answers, ask for confirmation. Bail cleanly if user declines.

## Step 2 — `flutter create` if needed

If the project doesn't yet exist (or platforms are missing), run:
```sh
flutter create . --org <bundle-prefix> --platforms <selected-comma-separated>
```
Skip if `pubspec.yaml` already declares the project and all selected platforms are already configured.

## Step 3 — Pubspec + analysis options

Overwrite `pubspec.yaml` from `templates/pubspec.yaml`:
- Set `name`, `description`.
- Inter font block under `flutter.fonts`.
- `assets:` block for `images/`, `icons/`, `lottie/`.
- `flutter_launcher_icons` block for the user's selected platforms.
- `flutter_native_splash` block (web excluded).
- Add only the opted-in situational packages from prompt 8.

Overwrite `analysis_options.yaml` from `templates/analysis_options.yaml`.

## Step 4 — `flutter pub get`

Required before any codegen / gen-l10n step. Fail loudly if it fails.

## Step 5 — Bundle the Inter font

Download `Inter-VariableFont.ttf` from `https://rsms.me/inter/font-files/InterVariable.ttf` (OFL-licensed, safe to bundle). Save to `assets/fonts/Inter-VariableFont.ttf`. If the network is unreachable, instruct the user to provide the file at that path and re-run.

## Step 6 — Asset placeholders

For `assets/launcher_icon.png`, `assets/launcher_icon_foreground.png`, `assets/splash.png`:
- If the user provided a path in prompt 6, copy that PNG to those locations (the foreground is the same source unless the user provides a separate one).
- Otherwise generate a 1024×1024 PNG: app's first letter (Inter Bold, white, sized to ~50% canvas) on the seed-color background. The foreground is the same letter on a transparent background. Write all three files.

## Step 7 — `lib/` scaffold

Overwrite/create the full tree from `templates/`:

```
lib/main.dart                                  # Path A inline init (copies templates/main.dart)
lib/app/app.dart                               # MultiBlocProvider + MultiBlocListener + appNavigatorKey
lib/app/injection.dart                         # configureDependencies(FlavorConfig)
lib/core/env/{flavor,flavor_config}.dart       # enum + FlavorConfig.byName
lib/core/error/{result,failures,exceptions,failure_localizer}.dart
lib/core/network/{dio_client,auth_interceptor,logging_interceptor,error_interceptor,token_storage,auth_api}.dart
lib/core/logging/app_logger.dart
lib/core/observability/app_bloc_observer.dart
lib/core/analytics/analytics_service.dart      # interface + NoopAnalyticsService
lib/core/flags/feature_flag_service.dart       # interface + NoopFeatureFlagService
lib/core/responsive/breakpoints.dart
lib/core/router/{app_router,routes,shell}.dart
lib/core/widgets/adaptive_scaffold.dart
lib/core/widgets/paginated_sliver.dart
lib/core/widgets/state/{page_loading,inline_loading_bar,empty_state,page_error,error_banner,error_snackbar}.dart
lib/core/widgets/state/skeleton/{shimmer,list_skeleton,card_skeleton}.dart
lib/core/theme/{app_theme,app_colors,app_text_styles}.dart
lib/core/pagination/page.dart
lib/core/assets/app_assets.dart
lib/l10n/app_en.arb                             # canonical failure_*, loading, retry, dismiss keys
lib/l10n/_untranslated_allow.txt
```

Plus opt-in extras:
- Sentry → `lib/core/observability/sentry_scrub.dart` + Sentry init block in `main.dart` + `sentry_flutter`/`sentry_dio` in pubspec.
- Connectivity → `lib/core/connectivity/connectivity_cubit.dart`.
- Feature flags → flag debug screen at `/debug/flags` (dev only).
- Push → `lib/core/notifications/push_routing.dart` + cold-start payload check in `main.dart`.

## Step 8 — Substitutions

For every file written:
- `my_flutter_app` → snake_case project name.
- `MyFlutterApp` (if any) → UpperCamelCase project name.
- `https://api.example.com` / `https://api.dev.example.com` → reasonable per-flavor placeholders for the user to replace.
- `String.fromEnvironment('FLAVOR', defaultValue: 'prod')` → `defaultValue:` set to whatever the user selected in prompt 4.

## Step 9 — Auth feature scaffold

Generate `lib/features/auth/` with:
- `domain/entities/user.dart`
- `domain/repositories/auth_repository.dart` exposing `Stream<AuthStatus> get status` and `Future<Result<...>>` methods for `signIn`, `signOut`, `currentUser`.
- `data/datasources/auth_remote_data_source.dart`
- `data/models/user_model.dart` (`@JsonSerializable`)
- `data/repositories/auth_repository_impl.dart` constructed with `AuthRemoteDataSource` + `TokenStorage`; owns the broadcast stream controller.
- `presentation/bloc/auth_bloc.dart` extending `HydratedBloc<AuthEvent, AuthState>`, subscribed to its OWN repository's status stream.
- `presentation/pages/login_page.dart` (placeholder).
- Wire `AuthRepository`, `AuthRemoteDataSource`, `AuthBloc` in `injection.dart`.
- Wire `GoRouter` with `refreshListenable: GoRouterRefreshStream(authRepo.status)` + the redirect chain (force-upgrade → onboarding → auth) + `navigatorKey: appNavigatorKey`.
- Wire App-root `MultiBlocListener` watching `AuthBloc` for `AuthUnauthenticated` → dispatches `XxxCleared` events to user-scoped blocs (none yet — comment placeholder).

## Step 10 — Onboarding + force-upgrade scaffold (when opted in)

When prompt 8 includes "Force-upgrade flow":
- `lib/features/onboarding/` with `OnboardingCubit extends HydratedCubit<bool>` and `OnboardingPage`.
- `lib/features/app_update/` with `AppUpdateCubit` reading `min_app_version` from `FeatureFlagService` and `ForceUpgradePage`.
- Add both to the redirect chain.

## Step 11 — Configs at root

Write from `templates/`:
- `l10n.yaml`
- `Makefile`
- `lefthook.yml`
- `.vscode/launch.json`
- `.github/workflows/ci.yaml`
- `.gitignore` updates: ensure `coverage/`, `.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies` are ignored.

## Step 12 — `test/` mirror

Create `test/` mirroring `lib/` exactly, with placeholder test files for each bloc, repository impl, and data source. Each placeholder uses `bloc_test` + `mocktail` per the testing reference.

## Step 13 — Codegen (correct order)

```sh
flutter pub get                                                # already done in step 4 — re-run if pubspec changed
dart run build_runner build --delete-conflicting-outputs       # JSON serializable
flutter gen-l10n                                                # AppLocalizations from ARB files
dart run flutter_launcher_icons                                 # generates platform icons
dart run flutter_native_splash:create                           # generates splash images
```

Halt at the first failure with the offending command and stderr.

## Step 14 — Smoke test (selected platforms)

Always:
```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Then per platform the user selected, on the matching host:
- Android: `flutter build apk --debug`
- iOS (macOS host only): `flutter build ios --no-codesign --debug`
- web: `flutter build web`
- macOS (macOS host only): `flutter build macos --debug`
- Windows (Windows host only): `flutter build windows --debug`
- Linux (Linux host only): `flutter build linux --debug`

Skip platforms whose host doesn't match. Print a summary with PASS/FAIL per build.

## Step 15 — Closing checklist

Print manual steps the slash command can't automate:
- **Xcode signing:** open `ios/Runner.xcworkspace`, set the development team.
- **Sentry (if opted in):** add the project DSN to `lib/core/env/flavor_config.dart` per flavor.
- **Firebase (if opted in):** run `flutterfire configure` to generate `firebase_options.dart`.
- **Push (if opted in):** add APNs key in App Store Connect; configure Firebase iOS bundle.
- **Replace placeholder icon** if the auto-generated one is in use.

## Idempotency contract

Re-running the slash command on a configured project must:
- Diff every file against the template-derived canonical version.
- Show the user a summary of files that differ.
- Ask before overwriting anything that has been hand-edited.
- Never silently revert customizations.

## What this slash command does NOT do

- Add `flutter_flavorizr`. Path A is the default; native flavors are an explicit per-project deviation documented in `references/situational-packages.md`.
- Create accounts on Sentry / Firebase / etc. The user provides DSNs and config files.
- Push to Git or open a PR.
- Generate documentation files (READMEs, etc.) unless explicitly requested.

## On failure

Halt at the first failed step. Print:
- Which step failed.
- The exact command and its stderr.
- A bulleted remediation list (most likely cause first).
- The state of files written so far — explicitly tell the user nothing was reverted.

The user fixes the cause and re-runs the slash command; idempotency does the rest.
