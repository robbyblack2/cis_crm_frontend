# MEMORY — Robby's Flutter BLoC Architecture Decisions

This file is the source of truth for every decision baked into this skill. SKILL.md and all templates compile from these decisions. When you (or a future agent) want to change the skill, change here first, then update SKILL.md and templates to match.

Append new decisions to the bottom. Never silently rewrite old ones — supersede them with a new entry that references what changed and why.

**Distribution model.** Project-based, no symlinks. The master copy of this skill lives at `/Users/Robby/Dev/new_skill/flutter-bloc-architect/`. Each new Flutter project gets its own copy at `<project-root>/.claude/skills/flutter-bloc-architect/`, made by `cp -r` from the master at project init. When the master is updated, run a sync script (or manual `cp -r`) into each project that needs the update — there is no automatic propagation, by design.

---

## Decision log

### 2026-05 — Initial lock

**Context.** First version of the skill. Goal: every Flutter app written under this skill follows the same stack, the same architecture, and the same BLoC contract so years of accumulated lessons compound rather than reset per project.

**Stack philosophy: lean base, situational templates.**
The base `pubspec.yaml` only pins what 100% of projects need. Common-but-not-universal packages (image caching, connectivity, URL launching, app info, deep DB, push notifications, analytics) live as templates in this skill — paste-ready code with the canonical setup, but not pinned by default. Add them per-project only when needed.

**Locked stack (runtime).**

| Package | Version | Why |
|---|---|---|
| `flutter_bloc` | `^8.1.6` | Official BLoC pattern. |
| `hydrated_bloc` | `^9.1.5` | Official. State persists across app restarts (auth, settings, theme, cart). |
| `bloc_concurrency` | `^0.2.5` | Official transformers — `droppable`, `restartable`, `sequential`, `concurrent`. Required on every event handler that fires from user input. |
| `equatable` | `^2.0.5` | `==`/`hashCode` via `props` list. The bloc-canonical equality solution per bloclibrary.dev. |
| `json_annotation` | `^4.9.0` | Pairs with `json_serializable` codegen. |
| `get_it` | `^7.7.0` | Service locator for the dependency graph. Manual registration in `lib/app/injection.dart`. |
| `go_router` | `^14.0.0` | Declarative routing. Auth-gated routes via `redirect`. |
| `dio` | `^5.4.0` | HTTP client with interceptors. |
| `formz` | `^0.7.0` | Bloc-team forms package. `FormzInput<T, E>` for fields, submission state for free. |
| `flutter_secure_storage` | `^9.2.2` | Tokens, refresh tokens (Keychain on iOS, Keystore on Android). |
| `shared_preferences` | `^2.3.0` | Non-sensitive prefs (theme mode, onboarding flag, locale). |
| `path_provider` | `^2.1.4` | Required by `hydrated_bloc` for storage directory. |
| `intl` | `^0.19.0` | i18n + date/number/currency formatting. Pairs with `flutter_localizations` from SDK. |
| `logger` | `^2.4.0` | General-purpose Dart logger. |
| `flutter_localizations` | (SDK) | Required for `MaterialApp.localizationsDelegates`. |

**Locked stack (dev).**

| Package | Version | Why |
|---|---|---|
| `very_good_analysis` | `^6.0.0` | VGV's strict lint set. Bloc-team-aligned. Supersedes `flutter_lints`. |
| `bloc_test` | `^9.1.7` | Official bloc testing helpers. |
| `mocktail` | `^1.0.0` | Null-safe mocks. Preferred over `mockito`. |
| `flutter_launcher_icons` | `^0.14.1` | Generate iOS+Android+web app icons from one source PNG. |
| `flutter_native_splash` | `^2.4.1` | Generate native splash screens cross-platform. |
| `build_runner` | `^2.4.13` | Codegen runner. |
| `json_serializable` | `^6.8.0` | JSON codegen — only codegen package in the stack. |

**Explicitly rejected.**

| Package | Why rejected |
|---|---|
| `freezed` / `freezed_annotation` | Heavier codegen pipeline. Native Dart 3 sealed classes + Equatable + hand-written `copyWith` covers the same ground with less tooling. Revisit if Dart macros (`data_class`) ever stabilize. |
| `injectable` / `injectable_generator` | Manual `get_it` registration is explicit and one less codegen surface. |
| `fast_immutable_collections` | With Equatable, plain `List`/`Map` already work for value equality (Equatable uses `DeepCollectionEquality`). The mutation-prevention angle isn't worth the dependency for a lean stack. |
| `fpdart` / `dartz` | Not in BLoC official docs. Replaced by hand-rolled `Result<T, F>` sealed class — clearer names (`Success`/`Failure` vs `Left`/`Right`), no dependency, same type safety. |
| `data_class` (Felix Angelov's) | Bleeding-edge Dart macros. Requires experimental flags. Revisit when macros are GA. |
| `flutter_lints` | Subset of `very_good_analysis`. Don't run both. |
| `dart_code_metrics` | Maintenance status declining; mostly absorbed into Dart analyzer. |

**Situational packages (templated, not pinned).**

When a project needs one of these, the skill has a reference doc + setup snippet ready. Add to project's `pubspec.yaml` then; do not pin to base.

| Need | Package |
|---|---|
| Network image cache | `cached_network_image` |
| Online/offline detection | `connectivity_plus` |
| App version display | `package_info_plus` |
| External URLs / mailto / tel | `url_launcher` |
| Crash + error reporting | `sentry_flutter` |
| Push notifications | `firebase_messaging` + `flutter_local_notifications` |
| Analytics | `firebase_analytics` or `mixpanel_flutter` |
| Local SQL DB | `drift` |
| Local NoSQL DB | `isar` v3 or `hive_ce` |
| Auth providers | `firebase_auth`, `google_sign_in`, `sign_in_with_apple` |
| Camera/images | `camera`, `image_picker`, `flutter_image_compress` |
| Permissions | `permission_handler` |
| Sharing | `share_plus` |
| Web view | `webview_flutter` |
| Maps | `google_maps_flutter` or `mapbox_maps_flutter` |
| Location | `geolocator` |
| Charts | `fl_chart` |
| Theming helper | `flex_color_scheme` |
| Animations | `flutter_animate`, `lottie` |
| Audio/video | `just_audio`, `video_player` + `chewie` |
| Time formatting | `timeago` |
| Bloc dev logger (alt) | `talker_bloc_logger` + `talker_dio_logger` |
| Env vars | `envied` |
| Remote config / flags | `firebase_remote_config` |
| Deep links | `app_links` |
| Type-safe routes | `go_router_builder` |
| Type-safe assets | `flutter_gen_runner` |
| Brick scaffolding | `mason_cli` |
| Golden tests | `alchemist` or `golden_toolkit` |
| Integration testing | `patrol` |

---

## Architecture contract

**Three-layer feature-first.** Every feature is a vertical slice with `data/`, `domain/`, `presentation/` subfolders. Shared cross-feature code lives in `lib/core/`. App-level wiring lives in `lib/app/`.

**Dependency direction points inward toward `domain/`.**
- `presentation/` imports from `domain/`.
- `data/` implements `domain/` interfaces.
- `domain/` imports nothing from the other two layers.
- Result: domain layer compiles without Flutter, repos are mockable, blocs are unit-testable.

**No feature imports another feature.** Cross-feature interaction goes through `core/` shared types, or via subscribing to another bloc's stream injected through DI. Never `import 'features/auth/...'` from `features/cart/`.

**One bloc per feature owns that feature's state.** Cross-feature side effects propagate via stream subscriptions, never direct `bloc.add(...)` calls between blocs.

**Repositories return `Future<Result<T, AppFailure>>`.** They never throw. Data sources may throw `AppException`s; repositories catch them and convert to `Failure<T, AppFailure>`. Bloc handlers exhaustively `switch` on the result.

**Three error files in `lib/core/error/`.**
- `result.dart` — generic `sealed class Result<T, F>` with `Success<T, F>` and `Failure<T, F>`.
- `failures.dart` — sealed `AppFailure` hierarchy: `NetworkFailure`, `ServerFailure`, `UnauthorizedFailure`, `ValidationFailure`, `CacheFailure`, `UnknownFailure`.
- `exceptions.dart` — sealed `AppException` hierarchy thrown by data sources: `ServerException`, `NetworkException`, `CacheException`, `UnauthorizedException`.

---

## State-class contract

Every state class follows all five rules:

1. `extends Equatable`.
2. Annotated `@immutable` (from `package:flutter/foundation.dart`).
3. Part of a `sealed` hierarchy (Dart 3 native sealed class).
4. All constructors are `const`.
5. `copyWith` is hand-written using the sentinel pattern when nullable fields need "set to null" support.

The shape of every feature state is at minimum: `Initial | Loading | Loaded | Error`. Variant names may be feature-specific (e.g., `AuthInitial | AuthLoading | AuthAuthenticated | AuthUnauthenticated | AuthError`).

`props` getter lists every field. Adding a field means updating `props` — checked by the bloc-verifier agent.

---

## DI contract

`get_it` registration in `lib/app/injection.dart`. Order is bottom-up:

1. **Leaves** (no dependencies) — `SecureStorage`, `SharedPreferences`.
2. **Data providers** — `Dio` (with interceptors), local DB clients.
3. **Data sources** — concrete implementations that depend on providers.
4. **Repositories** — depend on data sources, satisfy abstract domain contracts.
5. **Blocs** — depend on repositories.

**App-wide blocs are singletons** (`registerLazySingleton`): auth, theme, settings, anything that lives for the whole app.

**Feature blocs are factories** (`registerFactory`): created when their page mounts, disposed when popped.

**Widgets reach blocs via `BlocProvider`/`MultiBlocProvider`** at the page or app level — `BlocProvider.value(value: getIt<XxxBloc>())` for singletons, `BlocProvider(create: (_) => getIt<XxxBloc>())` for factories.

---

## State-management rules

**`Cubit` for load-only screens.** No concurrent flows, no debounced search, no multi-step form. Method calls in, states out. Less ceremony.

**`Bloc` for multi-action screens.** Login (with debounced validation), search (with debounce + cancel), forms with multiple async actions, file uploads.

**`HydratedBloc` for state that must survive app restarts.** Auth, theme, onboarding-completed, cart. Implement `toJson`/`fromJson`.

**`bloc_concurrency` transformer is explicit on every user-input event handler.**
- `droppable()` — submit buttons (don't queue duplicate submits).
- `restartable()` — search-as-you-type (cancel previous on new input).
- `sequential()` — ordered ops (queue file uploads).
- `concurrent()` — independent ops.

**UI binding rules.**
- `BlocBuilder` with `buildWhen` for granular rebuilds.
- `BlocListener` for one-shot side effects (snackbars, navigation, dialogs).
- `BlocConsumer` only when both are needed in the same widget.
- Avoid `context.watch<MyBloc>()` outside `BlocBuilder` — no `buildWhen` escape hatch.

---

## Routing contract

`go_router` only. Never `Navigator.push` directly.

Auth-gated routes use a `redirect` callback that reads `AuthBloc.state`:

```dart
redirect: (context, state) {
  final auth = context.read<AuthBloc>().state;
  final loggingIn = state.matchedLocation == '/login';
  if (auth is AuthUnauthenticated && !loggingIn) return '/login';
  if (auth is AuthAuthenticated && loggingIn) return '/';
  return null;
}
```

---

## Testing contract

`test/` mirrors `lib/` exactly. Every bloc has `*_bloc_test.dart`. Every repository impl has `*_repository_impl_test.dart`. Every data source has `*_data_source_test.dart`.

**Tools:** `bloc_test` for bloc tests, `mocktail` for mocks, `flutter_test` for widget tests.

**Pattern:**
- Bloc tests: `blocTest<XxxBloc, XxxState>` with `seed`, `act`, `expect` matching exact state sequences. Use mocked repos.
- Repository impl tests: instantiate impl with mocked data sources, assert `Result<T, F>` shape.
- Data source tests: use `mocktail` to mock `Dio`, assert request shape and exception throwing.

---

## Linting contract

`analysis_options.yaml` extends `package:very_good_analysis/analysis_options.yaml`. Additional rules:
- `prefer_const_constructors_in_immutables: true`
- `prefer_const_declarations: true`
- `prefer_const_literals_to_create_immutables: true`
- `require_trailing_commas: true`
- `sort_constructors_first: true`
- `avoid_print: true`

`*.g.dart` and `build/` excluded from analyzer.

No warnings in committed code. The flutter-tester agent treats analyzer warnings as test failures.

---

## Companion agents (defined in agents/)

1. **codegen-runner** — runs `dart run build_runner build --delete-conflicting-outputs`, watches for changes to annotated files (`@JsonSerializable`, `@TypedGoRoute` if added), reports stale `.g.dart` files.
2. **feature-scaffolder** — given a feature name, generates the full three-layer folder from `templates/feature/`, with the name substituted everywhere.
3. **bloc-verifier** — reads SKILL.md and inspects the codebase, flags violations: state class missing `Equatable` extension, missing `@immutable`, non-`const` constructor, missing field in `props`, repository that throws, feature that imports another feature, etc.
4. **flutter-tester** — runs `flutter analyze`, `flutter test`, parses output, reports failures with file:line locations.

---

### 2026-05 — Usecases removed; multi-repo blocs are the canonical pattern

**Context.** The original locked architecture left `domain/usecases/` as an optional folder per feature, with `core/usecase/usecase.dart` providing an abstract `UseCase<Type, Params>` base. After more thinking, this added overhead (extra files, scaffold ceremony, indirection through one-line wrappers) without earning its keep at the app scale this skill is meant for.

**Decision.** Remove usecases entirely.

- Deleted `templates/core/usecase/` and `templates/feature/domain/usecases/`.
- SKILL.md no longer references usecases. Replaced the optional-usecase guidance with an explicit "Repository orchestration" rule: blocs may take multiple repositories and orchestrate them directly in the handler.
- `references/architecture.md` now includes the canonical multi-repo bloc pattern (CheckoutBloc taking cart + payment + inventory) with a `switch (result)` chain at handler level.
- `agents/feature-scaffolder.md` no longer generates the `domain/usecases/` folder.
- `agents/bloc-verifier.md` now flags any reintroduction of `core/usecase/` or `domain/usecases/`.

**When to revisit.** If a future project hits a real "same action invoked from 4+ blocs" situation, reintroduce usecases via a fresh MEMORY entry. Until then, skip them.

### 2026-05 — Repository → data source layering rule

**Context.** A repository injecting `Dio` or `SecureStorage` directly skips the data source layer — the repo ends up doing both business logic AND raw I/O, becomes harder to test, and breaks the bloc-canonical 3-tier data layer (provider → data source → repository).

**Decision.** Repository impl constructors take only feature-scoped data sources. Each data source uses one or more `core/` providers internally.

- SKILL.md now contains a "Repository → data source rule" section.
- `references/architecture.md` has a "Repository → data source rule" section with WRONG/CORRECT examples.
- `agents/bloc-verifier.md` adds rules 13a and 13b to flag direct provider injection.

This formalizes what the existing `auth_repository_impl.dart` template already does: it takes `AuthRemoteDataSource` (and will take `AuthLocalDataSource` once the auth feature is realized), never `Dio` or `SecureStorage`.

---

### 2026-05 — Final structural cleanup (v1.9.0 — production-ready)

**Context.** After v1.8.0's e2e test verified the skill compiles and analyzes clean against a real Flutter SDK, a final pass cleaned up structural cruft so the skill is genuinely ready to drive real-world projects.

**Cleanup performed.**

1. **Removed Flutter build artifacts from `templates/`** that polluted the source during the e2e test: `templates/build/`, `templates/.dart_tool/`, `templates/.flutter-plugins-dependencies`, `templates/pubspec.lock`, `templates/lib/l10n/generated/`. Generated files belong to projects, not to the skill source.
2. **Added `templates/.gitignore`** that ignores all the above plus `ios/`, `android/`, `macos/`, `windows/`, `linux/`, `.metadata`, `.packages`. Future `flutter pub get` against the templates dir won't pollute it.
3. **Removed orphan templates.**
   - `templates/core/storage/secure_storage.dart` — superseded by `core/network/token_storage.dart`. The token-storage abstraction is the only place `flutter_secure_storage` is wrapped. Generic secure-storage wrapping is a project-by-project decision, not skill default.
   - `templates/core/forms/email_input.dart` — violated MEMORY's formz rule that "FormzInput subclasses live in `lib/features/<feature>/presentation/bloc/inputs/` by default; they migrate to `lib/core/forms/inputs/` only on the second feature that uses them." Pre-emptively shipping `core/forms/email_input.dart` was premature centralization.
4. **Rewrote `templates/core/theme/app_colors.dart`** down to a single `seed` constant + three semantic colors (`success`, `warning`, `info`) not in `ColorScheme`. Hand-rolled brand palettes are out; `ColorScheme.fromSeed` is in.
5. **Rewrote `templates/core/theme/app_theme.dart`** to use `ColorScheme.fromSeed(seedColor: AppColors.seed, brightness: ...)` for both light and dark themes. Material 3 generates compliant contrast pairs automatically. `FilledButton` replaces `ElevatedButton` (M3 default). `TextTheme.apply(fontFamily: 'Inter', ...)` plumbs the bundled font. **Both rules from MEMORY's theming entry are now actually implemented**, not just documented.
6. **Updated SKILL.md "Files in this skill" tree** to match the cleaned reality. Tree now includes the `commands/` directory, the `references/performance.md` and `agents/bloc-researcher.md` additions, the `core/` subfolders the previous tree elided (analytics, flags, observability, responsive, pagination, assets), the config files at root (`l10n.yaml`, `lefthook.yml`, `Makefile`, `.vscode/launch.json`, `.github/workflows/ci.yaml`).

**What this finalizes.**

- Skill source tree contains only canonical files. No build artifacts, no orphans, no drift between MEMORY rules and shipped templates.
- `ColorScheme.fromSeed` and Inter font wiring are now real, not aspirational.
- `.gitignore` prevents future pollution.
- SKILL.md's structural map matches the actual filesystem.

**Skill version bumped to v1.9.0.** Ready for real-world use.

**What's left for the user to verify by actually shipping a project.**

- The full auth flow (`AuthRepository.status` broadcast stream + `AuthBloc` HydratedBloc + interceptor refresh + App-root listener) — needs a real backend.
- `/configure-flutter-app` slash command's full pipeline — interactive prompts, Inter download, launcher icon placeholder generation, smoke-test loop. The e2e pass exercised the underlying templates manually; the slash command's orchestration is unverified.
- Native flavor opt-in path (situational `flutter_flavorizr`) — not exercised because Path A is the default.
- Performance hygiene rules in `references/performance.md` against a real DevTools profile — judgment-call decisions there can't be unit-tested.

These are project-level verifications; the skill's spine is finalized.

---

### 2026-05 — End-to-end skill test (Flutter 3.41.4) + version bumps

**Context.** After locking the v1.7.0 spine (TDD + performance + 8-agent cross-check + bloc-researcher), ran the skill end-to-end against a fresh `flutter create test_app` on the user's machine (Flutter 3.41.4 / Dart 3.11.1). Goal: catch every gap between "skill says X" and "real Flutter SDK does X" before the user starts building real apps.

**Bugs found and fixed.**

1. **`intl: ^0.19.0` incompatible with current Flutter SDK.** `flutter_localizations` pins `intl: 0.20.2`; pubspec resolution fails. Changed pin to `intl: any` so the SDK's pinned version always wins. Future Flutter SDK bumps won't break the skill.
2. **`synthetic-package: false` in `l10n.yaml` is deprecated** (Flutter 3.27+). Removed; `output-dir: lib/l10n/generated` already gives non-synthetic output.
3. **`hydrated_bloc: ^9.1.5` API mismatch.** The skill's `main.dart` template uses `HydratedStorageDirectory.web` and `HydratedStorageDirectory(<path>)` — that API only exists in `hydrated_bloc 10.x`. Bumped:
   - `flutter_bloc: ^8.1.6` → `^9.1.0`
   - `hydrated_bloc: ^9.1.5` → `^10.1.1`
   - `bloc_concurrency: ^0.2.5` → `^0.3.0`
   - `bloc_test: ^9.1.7` → `^10.0.0`
4. **`main.dart` imported `flavor.dart` but used `FlavorConfig`** (which lives in `flavor_config.dart`). Fixed.
5. **Three template files had unused imports** (`shell.dart`, `app_router.dart`, `injection.dart`). Removed.
6. **Five widget templates violated `always_put_required_named_parameters_first`** (`super.key` came before `required`). Reordered: `PageError`, `EmptyState`, `PaginatedSliver`, `AdaptiveScaffold`, `Shimmer`.

**Verified working on Flutter 3.41.4 / Dart 3.11.1.**

- `flutter pub get` → resolves cleanly with the new pins.
- `flutter gen-l10n` → generates `lib/l10n/generated/app_localizations*.dart` from the canonical ARB.
- `flutter analyze` → **0 errors, 0 warnings.** 88 info-level lint messages remaining (mostly `always_use_package_imports` on relative imports the templates use; benign and resolved by `/configure-flutter-app` substituting the real package name).
- `flutter test` → **8/8 smoke tests pass** covering `FlavorConfig.byName`, `AppFailure` subtypes including `ValidationFailure(fieldErrors)`, `Result<T, AppFailure>` shape, `Page<T>` pagination type.
- `flutter build web` → **succeeds** (22.8s compile). Output at `build/web`.

**Environment-blocked (not skill bugs).**

- `flutter build apk --debug` — fails on the user's Flutter 3.41.4 with an AGP 9 `android.newDsl` incompatibility. Affects every newly-created project on this Flutter version, not specific to the skill. User's Flutter SDK needs an upgrade or an opt-out per the [AGP 9 migration guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-agp-9).
- `flutter build macos` — fails because the test project was created with `--platforms=ios,android,web` (skill-test scope), not because of a template bug.

**Skill version bumped to v1.8.0** to capture the version-pin fix and template cleanups. Any project pinned to v1.7.0 should re-run `/configure-flutter-app` to pick up the corrected pubspec.

**What this proves.**

- The locked stack actually resolves and analyzes clean on a current Flutter SDK.
- The Dart-side flavor pattern (`String.fromEnvironment('FLAVOR', defaultValue: 'prod')`) works as intended — the smoke test directly exercises `FlavorConfig.byName`.
- The error-handling shape (`Result` + `AppFailure` + `ValidationFailure(fieldErrors)`) compiles and behaves correctly under tests.
- The web build path is confirmed working — bare `flutter run` on web will work for projects scaffolded by this skill.

**What still needs real-project verification.**

- The full auth flow (`AuthRepository.status` broadcast stream + `AuthBloc` HydratedBloc + interceptor refresh + App-root listener) — not exercised by this smoke test because it requires a real backend. Should be tested on the first real app the skill scaffolds.
- The native flavor opt-in path (situational `flutter_flavorizr`) — not exercised because the default Path A doesn't use it.
- The `/configure-flutter-app` slash command end-to-end — this test exercised the underlying templates manually; the slash command's pipeline (interactive prompts, copy + substitute, idempotency) needs a real run.

---

### 2026-05 — Performance hygiene as a hard rule

**Context.** Performance is treated as a "we'll profile later" afterthought in many Flutter projects, which then ship with overdraw, repaint cascades, and image-cache OOMs that are 10× cheaper to prevent than to fix retroactively. This skill encodes the basic hygiene up front.

**Decisions.**

1. New SKILL.md "Performance hygiene" hard-rule section with five baseline rules:
   - `const` everywhere it compiles (already enforced by `very_good_analysis`).
   - `BlocBuilder.buildWhen` mandatory for non-trivial builders; prefer `BlocSelector<X, S, T>` for one-slice reads.
   - `RepaintBoundary` around frequently-repainting independent subtrees (Lottie, custom paint, video, shimmer, animated icons, charts, complex list items). NOT a blanket rule — speculative wrapping costs GPU memory.
   - `ListView.builder` for variable-length lists; `ListView(children: [...])` with >5 items is a violation.
   - `Image.network` requires `cacheWidth` / `cacheHeight` sized to render dimensions (multiplied by `devicePixelRatio`).
2. New `references/performance.md` deep-dive covering when to use / not use `RepaintBoundary`, the DevTools "Highlight Repaints" overlay, `BlocSelector` vs `BlocBuilder.buildWhen`, `AnimatedBuilder` `child:` parameter trick, hot-path animations via `ValueNotifier` instead of bloc emissions, `Opacity` vs `FadeTransition`, image cache sizing rules, and a list of common offenders.
3. New bloc-verifier rules 44–47 that mechanically flag the rules where it can: large `ListView(children:)` arrays, missing image cache dimensions, `BlocBuilder` without `buildWhen` over a non-trivial builder, animated `Opacity`.
4. Existing `core/widgets/state/skeleton/shimmer.dart` template updated: now wraps its animating subtree in `RepaintBoundary` and uses the `AnimatedBuilder.child:` parameter so the static child is built once.
5. SKILL.md "When to load which reference" table gains a row for `references/performance.md`.

**Why mandatory.** The verifier rules are mechanical because the offenders are mechanical: a 4000×3000 image decoded for a 100×100 thumbnail is always wrong; a `ListView(children:)` with 200 items is always wrong; a 200-line `BlocBuilder` without `buildWhen` is always wrong. Judgment-call decisions (where exactly a `RepaintBoundary` earns its keep) live in `references/performance.md` with the DevTools profiling instructions — the only honest source of truth for "did this change actually help."

**When to revisit.** When a project's profiling consistently shows another offender pattern that the rules don't cover (e.g., specific custom-paint patterns, web-specific repaint issues), promote the new pattern to a rule via a new MEMORY entry.

---

### 2026-05 — 8-agent cross-check vs official BLoC docs (finalization)

**Context.** After locking the v1.5.0 spine, eight parallel agents (mixed across opus / sonnet / haiku) re-audited the skill against `bloclibrary.dev`, `felangel/bloc` repo, `pub.dev` package pages, and the DCM lint rules. Each agent owned one slice (state modeling, cross-feature reactions, Bloc-vs-Cubit, HydratedBloc, repo + error handling, testing, naming, DI). The results are recorded so future maintainers can tell what's documented-aligned, what's deliberate divergence, and what was fixed in this pass.

**Aligned with official guidance (no change needed).**
- State-class five rules — directly distilled from [bloclibrary.dev/modeling-state](https://bloclibrary.dev/modeling-state/).
- Sealed hierarchy as default state shape — endorsed.
- Formz single-class form state with `FormzSubmissionStatus` — precedent in the official `flutter_login` tutorial.
- Cross-feature "no bloc imports another bloc" rule — verbatim from [bloclibrary.dev/architecture](https://bloclibrary.dev/architecture/) and DCM `avoid-passing-bloc-to-bloc`.
- Reactive-repository pattern (`AuthRepository.status` broadcast stream) — matches `flutter_login`'s `AuthenticationRepository` exactly; the skill's use of `StreamController.broadcast()` is an improvement on the example's single-subscription controller.
- Repo→data-source layering (no `Dio`/`SecureStorage` in repo constructors) — matches `flutter_weather`'s `WeatherRepository(WeatherApiClient)` shape.
- HydratedBloc `kIsWeb`/`HydratedStorageDirectory.web` web-init pattern — current API, matches package README.
- Naming: event past-tense + state past-tense + `XxxBloc` / `xxx_bloc.dart` files — all match [bloclibrary.dev/naming-conventions](https://bloclibrary.dev/naming-conventions/).
- `bloc_test` API surface and `whenListen` widget-test pattern — matches the package docs.

**Project-stricter than official (deliberate; documented in references).**
- **App-root `MultiBlocListener` for cross-feature reactions.** Docs allow any presentation-layer location; this skill mandates `lib/app/app.dart`. Centralization beats scattering.
- **Only the owning bloc subscribes to its repository's reactive stream.** Docs permit multiple blocs sharing one repo's stream; this skill routes those reactions through the App-root listener instead. Avoids cross-feature coupling at the repo layer.
- **Mandatory `bloc_concurrency` transformer on every user-input handler.** Docs treat transformers as opt-in; the official `flutter_login` example declares none. This skill flags missing transformers via the bloc-verifier — concurrency intent must be explicit at the call site.
- **Repos return `Result<T, AppFailure>` and never throw.** Docs' `flutter_weather` and `flutter_login` examples let typed exceptions propagate to the bloc handler. This skill places the catch boundary inside the repo. Self-documenting signatures + no `try/catch` in handlers.
- **`get_it` over `RepositoryProvider`/`MultiRepositoryProvider`.** Docs center on widget-tree DI via `RepositoryProvider`. This skill uses `get_it` for the full graph so non-widget code (interceptors, services) can resolve deps without `BuildContext`.
- **Mandatory TDD with mechanical enforcement** (lefthook pre-commit + CI diff check + bloc-verifier rules 36–41). Docs treat `bloc_test` as a tool, not a workflow mandate. The skill's stricter posture is project policy, not a quote.
- **Pagination shape — sealed hierarchy with `LoadingMore` as its own variant.** Docs' `flutter_infinite_list` uses a flatter `Initial | Success | Failure + hasReachedMax`. The skill splits `LoadingMore` so UI can distinguish fetching-more from done-loading without inspecting last-dispatched event.
- **No `Either`/`dartz`/`fpdart`.** Docs are silent on the question. The skill picks typed `Result` for naming clarity (`Success`/`Failure` over `Right`/`Left`).

**Bugs found and fixed in this pass.**
- `core/error/exceptions.dart` had no `ValidationException` — server-side `400` with `fieldErrors` would fall through to `UnknownFailure`. **Fixed**: added `ValidationException(message, {fieldErrors})` and updated the `_toFailure` switch in `references/error-handling.md`.
- `references/bloc-vs-cubit.md` showed `SubmitPressed` and `NotificationTapped` (UI-action verbs). **Fixed**: renamed to `LoginSubmitted` and `NotificationReceived` (domain past-tense). Added a Naming section pointing at `bloclibrary.dev/naming-conventions`.
- `references/bloc-vs-cubit.md` framed the rule as "load-only vs multi-action screens." **Fixed**: reframed as capability-based ("need an `EventTransformer` or auditable event log") matching the docs' actual criterion.
- `references/hydrated-bloc.md`'s setup snippet had no `kIsWeb` branch — inconsistent with `SKILL.md` and `templates/main.dart`. **Fixed**: added `kIsWeb` ternary, plus notes on `fromJson` exception fallback, logout `clear()`, and the rehydration race when subscribing to streams in the constructor.
- `references/testing.md` had a duplicated `## Bloc tests` header and listed only four blocTest params. **Fixed**: deduplicated header; expanded the param list to all eleven (`build`, `setUp`, `seed`, `act`, `wait`, `expect`, `errors`, `verify`, `tearDown`, `skip`, `tags`); added `MockBloc`/`MockCubit` example; inlined the canonical HydratedBloc `MockStorage` setUp.

**Conventions added in this pass.**
- Every reference doc that takes a project-stricter position now carries a "Project-stricter than docs" or "Deliberate departure from official examples" callout with the rationale. Future readers can tell at a glance which rules are quoted vs which are local policy.
- Skill version bumped to v1.6.0.

**Sources verified.**
- [bloclibrary.dev/modeling-state](https://bloclibrary.dev/modeling-state/), [bloclibrary.dev/bloc-concepts](https://bloclibrary.dev/bloc-concepts/), [bloclibrary.dev/architecture](https://bloclibrary.dev/architecture/), [bloclibrary.dev/flutter-bloc-concepts](https://bloclibrary.dev/flutter-bloc-concepts/), [bloclibrary.dev/naming-conventions](https://bloclibrary.dev/naming-conventions/), [bloclibrary.dev/testing](https://bloclibrary.dev/testing/).
- `felangel/bloc` examples: `flutter_login`, `flutter_weather`, `flutter_infinite_list`.
- pub.dev: `flutter_bloc`, `bloc_concurrency`, `bloc_test`, `hydrated_bloc`.
- DCM: `avoid-passing-bloc-to-bloc` lint rule.

---

### 2026-05 — `bloc-researcher` agent + canonical-sources index

**Context.** Several decisions in this skill — most prominently the cross-feature reactions rule — were corrected mid-grilling because the original draft contradicted official BLoC team guidance. Anchoring the skill to authoritative sources (and making it cheap to verify) reduces that drift going forward.

**Decision.**

1. New agent `agents/bloc-researcher.md`. Its job: given a clearly-scoped question, fetch the relevant pages from the canonical BLoC sources, return a structured summary with direct quotes and URLs, and report a confidence level. The agent never modifies code or MEMORY; it only produces evidence the parent agent uses to make decisions.
2. Canonical-sources index added to `SKILL.md` under "Canonical BLoC sources" — five tiers (official docs → felangel/bloc repo → pub.dev → aligned tooling → community-level). Every architectural rule in this skill should trace back to one of these.
3. **Citation convention** for any new MEMORY entry that takes an architectural position: link to a specific page (not the root), include a short quote, prefer Tier 1–2 sources over Tier 3+. Existing entries already follow this for the cross-feature-reactions decision; future entries match the format.
4. **When to invoke `bloc-researcher`:**
   - Before locking a new MEMORY decision that takes a position on contested architecture.
   - When grilling sessions hit a question whose answer should come from an authoritative source.
   - When reconciling community advice with the skill's existing rules.
   - NOT for quick lookups already answered in the references — those don't need re-research.

**Tier 1 sources of record:** bloclibrary.dev's Architecture, Bloc concepts, Flutter Bloc concepts, Modeling state, Naming conventions, Testing, Migration. **Tier 2:** felangel/bloc repo, examples, issues, discussions, CHANGELOGs. Full list lives in `SKILL.md` and `agents/bloc-researcher.md`.

**Why this matters.** The original v1.0 draft of this skill encoded "CartBloc takes AuthBloc in its constructor" as the canonical cross-feature pattern — a direct violation of the BLoC team's position. The correction came from one round of `WebFetch`. Building the research agent into the skill means future contradictions get caught the same way, by anyone, on demand.

---

### 2026-05 — TDD is mandatory (red-green-refactor for every change)

**Context.** Robby has an overall `tdd` skill that governs all development. This skill must reiterate and reinforce that contract for Flutter work specifically — without TDD baked in, the testing rules below get treated as "tests are required" rather than "tests come first."

**Decision.**

1. **Every change in a Flutter project under this skill follows the red-green-refactor loop.** Implementation code is not written before its driving test exists.
2. **Order for a new feature** matches the architecture's inside-out direction. For each layer: write the failing test, write the minimum impl to pass, refactor, re-run. Then move to the next layer:
   - Entity equality test → entity → green
   - Bloc test (every event-to-state path) → bloc + states → green
   - Repo impl test (every exception → failure mapping branch) → repo impl → green
   - Data source test (request shape + exception throwing) → data source → green
   - Widget test (loading / loaded / empty / error) → page + view widgets → green
3. **Bug fixes also follow TDD.** Write a failing test demonstrating the bug, then fix. A fix without a regression test is incomplete.
4. **`feature-scaffolder` emits failing tests + minimum stubs.** A freshly scaffolded feature, when `flutter test` runs against it, must produce a meaningful red bar (assertion mismatches or `UnimplementedError`) that the user then turns green via the loop. Scaffolds never produce all-green test files paired with empty implementations — that defeats the loop's purpose.
5. **`bloc-verifier` enforces "every source file has its test."** Missing `*_bloc_test.dart` / `*_repository_impl_test.dart` / `*_data_source_test.dart` next to a source file is a violation. Every public bloc event has at least one `blocTest`. Every `Failure(error: final XxxFailure _)` mapping branch in a repo impl has a corresponding `test('converts XxxException to XxxFailure', ...)`.
6. **The `tdd` skill remains the procedural source of truth.** This entry adds the Flutter-specific particulars (which test types match which source files, what "minimum stub" looks like, the inside-out layer order) on top of the general red-green-refactor rules in that skill.

**Enforcement (multiple, redundant — defense in depth).** A non-negotiable rule needs more than documentation:

- **`lefthook` pre-commit hook** rejects any commit that touches `lib/features/**`, `lib/core/**`, or `lib/app/**` (excluding generated `*.g.dart` etc.) without a corresponding change under `test/`. Bypass requires `--no-verify` and a commit-message explanation.
- **CI workflow** runs the same diff check as a `tdd-diff-check` job on every PR, so a `--no-verify` commit doesn't slip through.
- **`bloc-verifier` rules 36–41** flag missing test files for blocs / cubits / repo impls / data sources / pages / `core/` services, and flag public bloc events / cubit `emit`-calling methods / repo impl public methods / repo failure-mapping branches without referencing tests.
- **`feature-scaffolder`** emits failing tests + minimum stubs (returning `UnimplementedError` / `Initial`) — the user's first interaction with a fresh feature is a red bar.
- **`flutter-tester`** runs `dart format` + `flutter analyze` + `flutter test` as its mission; the format / analyze / test triplet is required to declare any change "done."

**When to revisit.** Never. TDD is a foundational discipline; if a project's pace makes red-green-refactor painful, the cause is in the test-design, mocking, or build-time, not in the rule itself.

---

### 2026-05 — Q10–Q19 batched decisions (all-recommended path)

**Context.** User accepted the recommended option for every remaining grilling question. Recording them as a single batched entry; if a specific decision needs revisiting after real-world use, supersede it with a new entry.

---

#### Q10 — Analytics + crash reporting

1. **Sentry is the canonical crash reporter, opt-in per project** via `FlavorConfig.sentryDsn`. `sentry_flutter` stays in `references/situational-packages.md`. When DSN is non-null, `main.dart` wraps `runApp` in `SentryFlutter.init(...)`.
2. **No `ErrorReporter` interface.** `AppBlocObserver.onError` and the global `FlutterError` / `PlatformDispatcher` handlers each have an inline `if (Sentry.isEnabled) Sentry.captureException(...)` after the log call. Three sites, one conditional each. Promote to interface only if a third destination shows up.
3. **PII scrubbing is mandatory and ships at `lib/core/observability/sentry_scrub.dart`.** Default scrubber strips emails, IPs, cookies, request bodies; keeps stable user IDs only. Wired via `o.beforeSend = scrubPii` in `SentryFlutter.init`.
4. **State-type breadcrumbs only.** `AppBlocObserver.onChange` pushes breadcrumbs with `bloc type: state type` — never state contents. Aligns with the no-state-contents-in-logs rule.
5. **Sentry APM enabled with low default sample rates:** `tracesSampleRate: 0.1` in prod, `1.0` in dev. `sentry_dio` interceptor wired automatically when Sentry is enabled.
6. **Analytics: ship the interface with a no-op default impl.** `abstract interface class AnalyticsService` at `lib/core/analytics/analytics_service.dart` exposes `identify`, `track`, `screen`, `reset`. Default impl is no-op. Projects register their real impl (`FirebaseAnalyticsService`, `MixpanelAnalyticsService`, etc.) when they enable analytics.
7. **Analytics events fire from `BlocListener` widgets,** never from inside bloc handlers. The App-root `MultiBlocListener` is the canonical fire site for app-wide events; page-level listeners cover page-scoped events.
8. **No PII in analytics properties.** Documented contract; not auto-verified.

---

#### Q11 — Connectivity / offline

1. **`connectivity_plus` stays situational.** Most apps don't need explicit offline awareness; failed network calls already surface as `NetworkFailure`.
2. **When a project adds `connectivity_plus`,** the canonical wiring is a `ConnectivityCubit` at `lib/core/connectivity/connectivity_cubit.dart` exposing `enum ConnectivityStatus { online, offline }`. Not `HydratedCubit` — connectivity is transient.
3. **Offline indicator is a banner at App root,** shown via the same App-root `MultiBlocListener` that handles cross-feature reactions. When `ConnectivityStatus.offline`, show a non-dismissable `MaterialBanner`; when `online`, dismiss.
4. **Repositories do NOT change behavior based on connectivity.** They make the call, fail with `NetworkFailure`, and the UI shows the failure. True offline-first (cache fallbacks, write queues) is a per-project deviation, not a default.

---

#### Q12 — Feature flags / remote config

1. **`FeatureFlagService` interface at `lib/core/flags/feature_flag_service.dart`** with a no-op default impl that always returns hardcoded defaults. Same pattern as `AnalyticsService`.
2. **Default values ship in code.** Every flag has a hardcoded default in `FeatureFlags` — the app must always work without the remote config service answering.
3. **Projects opt into a real impl per-package** (`firebase_remote_config`, `launchdarkly_flutter_client_sdk`, etc.) and register it in DI. `firebase_remote_config` stays situational.
4. **Flags are read on demand**, not cached in a bloc. Reading is synchronous (`flagService.boolValue('flag_name')`) and returns the cached value the service holds. Refresh is a separate background call.
5. **Flag overrides for QA:** when `FlavorConfig.flavorName == 'dev'`, the impl exposes a debug screen at `/debug/flags` listing all known flags with toggle UI. Settings are stored locally in `SharedPreferences` and override remote values until cleared.

---

#### Q13 — Shell routes / bottom nav

1. **`StatefulShellRoute.indexedStack` for tabbed shells.** Each tab is a separate `Navigator` so per-tab navigation state survives tab switches. Located at `lib/core/router/shell.dart`.
2. **Adaptive shell widget** at `lib/core/widgets/adaptive_scaffold.dart`. Picks navigation surface by viewport width:
   - `< 600 dp` (compact) — `NavigationBar` at bottom.
   - `600–840 dp` (medium) — `NavigationRail` on the left.
   - `> 840 dp` (expanded) — `NavigationDrawer` open permanently.
   The same `StatefulShellRoute` drives all three; the shell widget chooses how to render.
3. **No `flutter_adaptive_scaffold` package.** Hand-rolled (~120 lines). Stays out of dependencies.

---

#### Q14 — Type-safe routes

1. **No `go_router_builder`.** Second codegen pipeline; not worth the cost.
2. **String path constants in `lib/core/router/routes.dart`:**
   ```dart
   abstract final class Routes {
     static const home = '/';
     static const login = '/login';
     static const profile = '/profile';
     static String product(String id) => '/product/$id';
   }
   ```
3. **Bloc-verifier rule:** any string literal matching `r'^/[a-z]'` outside `routes.dart`, the router config file, and tests is a violation. Forces use of the `Routes` constants.

---

#### Q15 — Deep linking + push notifications → route

1. **`app_links` stays situational.** Universal/app-link config (associated domains, intent filters) is per-project; the skill ships only the Dart-side pattern.
2. **Single navigator key — `appNavigatorKey: GlobalKey<NavigatorState>`** registered in `lib/app/app.dart` and passed to `MaterialApp.router`. Used by:
   - Push notification handlers (cold-start via `getInitialMessage`, warm via `onMessageOpenedApp`).
   - The auth interceptor for "session expired" forced redirects.
   - The `tr(...)` localization escape-hatch helper.
3. **Push payload → route:** notification handlers parse a `route` field from the payload and call `appNavigatorKey.currentContext!.go(route)`. The skill ships a small `lib/core/notifications/push_routing.dart` helper with the parsing + null-safety.
4. **Cold-start payload check** runs in `main.dart` after `configureDependencies` and before `runApp`. If a payload is present, the helper stores it; the App widget reads it after first frame and navigates.

---

#### Q16 — Onboarding + force-upgrade

1. **`OnboardingCubit extends HydratedCubit<bool>`** tracking a single boolean `seenIntro`. App-wide singleton in DI.
2. **Router redirect chain (highest priority first):**
   1. Force-upgrade required → `/force_upgrade` (only when `AppUpdateCubit` says so).
   2. Onboarding not seen → `/onboarding`.
   3. Auth gate (existing rule).
   4. Otherwise no redirect.
3. **Force-upgrade is opt-in** via the feature-flag service. `AppUpdateCubit` reads `min_required_version` from `FeatureFlagService.stringValue('min_app_version', defaultValue: '0.0.0')`, compares to `package_info_plus.version`, and emits `UpdateRequired | UpdateOptional | UpToDate`. `package_info_plus` is situational; force-upgrade is added per-project.
4. **`/onboarding` and `/force_upgrade` are page templates** in `templates/feature/` that projects can copy and customize.

---

#### Q17 — Widget composition + adaptive UI + a11y

1. **Adaptive layout is mandatory by default.** Every page that has a list/grid uses `LayoutBuilder` + the breakpoints from `lib/core/responsive/breakpoints.dart`:
   ```dart
   abstract final class Breakpoints {
     static const compact = 600.0;     // phone
     static const medium = 840.0;      // tablet portrait, foldable open
     static const expanded = 1200.0;   // tablet landscape, desktop
   }
   ```
2. **Material 3 only.** `ThemeData(useMaterial3: true)`. No M2 fallbacks.
3. **Dark + light theme parity is mandatory.** Every project ships both themes from day one. `ThemeMode` lives in a `ThemeCubit extends HydratedCubit<ThemeMode>` (already implied by the existing theming reference; locking it as mandatory).
4. **Page-level widget composition rule.** Pages live in `presentation/pages/<page>_page.dart` and consist of: a `Scaffold`, one `BlocBuilder`, one `BlocListener`, and a body widget that takes the state as a constructor parameter. The body widget is in the same file unless it grows past ~200 lines, then it moves to `presentation/widgets/<page>_view.dart`. Keeps page files focused.
5. **Accessibility (mandatory rules, verified by bloc-verifier):**
   - Every `IconButton` has a non-null `tooltip:`.
   - Every `Image` (raster or svg) has a non-null `semanticLabel:` unless explicitly decorative (then `excludeFromSemantics: true`).
   - Every `Text` respects `MediaQuery.textScaler` automatically (do not pass `textScaleFactor: 1.0` — that breaks dynamic type).
   - Every interactive widget has a minimum 48dp tap target.
   - Color contrast is checked at theme-creation time using `ColorScheme.fromSeed` — Material 3 generates compliant pairs.
6. **Reusable widget library** at `lib/core/widgets/` ships with day-one widgets: `AdaptiveScaffold`, `PageLoading`, `PageError`, `EmptyState`, `ErrorBanner`, `ErrorSnackbar`, `ListSkeleton`, `CardSkeleton`, `Shimmer`, `PaginatedSliver`. Page composition starts from these.
7. **No `responsive_framework` / `flutter_screenutil` / similar packages.** Hand-rolled breakpoints + `LayoutBuilder` + `MediaQuery` cover what's needed.

---

#### Q18 — CI / pre-commit

1. **`lefthook` for pre-commit hooks.** Cross-platform, single YAML config, no Ruby/Python dependency.
   ```yaml
   # lefthook.yml
   pre-commit:
     parallel: true
     commands:
       format:
         glob: "*.dart"
         run: dart format --set-exit-if-changed {staged_files}
       analyze:
         glob: "*.dart"
         run: flutter analyze
   ```
2. **GitHub Actions workflow** at `.github/workflows/ci.yaml`. Checks per push and PR:
   - `dart format --set-exit-if-changed`
   - `flutter analyze`
   - `flutter test`
   - `flutter build apk --debug`
   - `flutter build ios --no-codesign --debug` (on macos runner)
   - `flutter build web`
3. **Required checks** for merges to `main`: format, analyze, test. Builds are reported but not gating (slow runners, occasional infra flakes — investigate manually).
4. **Skill ships both files** in `templates/ci/`.

---

#### Q19 — Coverage / goldens / integration

1. **Coverage target ~70%, no CI gate.** Hard percentage gates incentivize useless tests. Watch the trend in PR reviews instead.
2. **Required tests (already locked):** every bloc has `*_bloc_test.dart`; every repository impl has `*_repository_impl_test.dart`; every data source has `*_data_source_test.dart`. Widget tests for key user flows.
3. **Golden tests stay situational.** When a project adds them, use `alchemist` (Bloc-team-ish) over `golden_toolkit`. `alchemist` handles cross-platform gold-file divergence cleanly.
4. **Integration tests stay situational.** When a project adds them, use `patrol`. Native interactions (permissions dialogs, system pickers, push notifications) are the killer features `flutter_test` integration_test can't handle.
5. **Coverage report** generated by `make coverage` → `flutter test --coverage` then `genhtml coverage/lcov.info -o coverage/html`. Skill ships the Makefile target.

---

### 2026-05 — Asset organization

**Context.** Without canonical asset rules, every project invents its own folder layout, naming, and reference style.

**Decisions.**

1. **Folder layout.** Standard structure under `assets/`:
   ```
   assets/
   ├── images/                       # in-app raster + svg images
   ├── icons/                        # in-app icons (only used when not Material Icons)
   ├── fonts/                        # bundled custom font (Inter by default, see below)
   ├── lottie/                       # situational
   ├── launcher_icon.png             # 1024×1024 source for flutter_launcher_icons (build input)
   ├── launcher_icon_foreground.png  # Android adaptive foreground (build input)
   └── splash.png                    # source for flutter_native_splash (build input)
   ```
   The three root-level PNGs are build inputs only — not bundled with the app.
2. **Naming: `snake_case_lowercase` only.** No spaces, no camelCase. Density variants live in `2.0x/` and `3.0x/` subfolders with the same filename.
3. **Type-safe asset references via a hand-rolled constants class** at `lib/core/assets/app_assets.dart`. No `flutter_gen_runner` — keeps the codegen budget at one tool. Bloc-verifier flags any string literal matching `r'^assets/.+'` outside this file or `pubspec.yaml`.
4. **Material Icons are the default for all in-app icons.** Cover ~80% of icon needs natively. SVG support (via `flutter_svg`) stays in `references/situational-packages.md` — added per-project only when a design genuinely requires SVG icons. The `assets/icons/` folder exists but is empty in the default scaffold.
5. **Custom font: Inter, bundled.**
   - Files: `assets/fonts/Inter-VariableFont.ttf` (variable font — single file covers all weights).
   - License: SIL OFL 1.1 — bundled commercial-app safe.
   - Declared in `pubspec.yaml`; set as `Theme.textTheme`'s `fontFamily: 'Inter'` in `app_theme.dart`.
   - Override path: a project that wants a different font replaces the file in `assets/fonts/`, updates the pubspec entry, and updates the theme — three edits.
   - Why not `google_fonts` package: runtime download, first-launch latency, network dependency. Bundling is cleaner.
6. **Launcher icon — all six platforms.** `flutter_launcher_icons` config in `pubspec.yaml` covers Android (with adaptive icon), iOS, web, Windows, macOS, Linux.
   - When the user does not provide a `launcher_icon.png` at `/configure-flutter-app` time, the slash command auto-generates a 1024×1024 placeholder: app's first letter centered on a flat color background. This is enough for the build to succeed; the user replaces it later.
7. **Native splash — five platforms.** `flutter_native_splash` config covers Android (with Android 12+ block), iOS, Windows, macOS, Linux. **Web excluded** — `index.html` renders instantly, a splash there just adds a flash.
8. **`pubspec.yaml` assets block written by `/configure-flutter-app`:**
   ```yaml
   flutter:
     uses-material-design: true
     generate: true   # required for flutter gen-l10n
     fonts:
       - family: Inter
         fonts:
           - asset: assets/fonts/Inter-VariableFont.ttf
     assets:
       - assets/images/
       - assets/icons/
       - assets/lottie/
   ```
   Trailing slashes mean "include everything in the folder." Removing the line is one edit when a folder isn't used.
9. **`AppAssets` enforcement.** Bloc-verifier rule: only `lib/core/assets/app_assets.dart` and `pubspec.yaml` may contain string literals matching `r'^assets/.+'`. Any other occurrence is a violation with a fix suggestion to add a constant to `AppAssets`.

**Generated files:**
```
lib/core/assets/app_assets.dart
assets/images/                 # empty
assets/icons/                  # empty
assets/fonts/Inter-VariableFont.ttf
assets/lottie/                 # empty
flutter_launcher_icons.yaml    # configured for all six platforms
```

---

### 2026-05 — Localization workflow

**Context.** `flutter_localizations` + `intl` are pinned but the workflow (which generator, where ARB files live, when to translate, runtime locale change) was unspecified.

**Decisions.**

1. **Use Flutter's built-in `flutter gen-l10n`.** Not `slang` or any third-party type-safe alternative — keeps the codegen budget at one tool (`json_serializable`).
2. **ARB files live at `lib/l10n/`.** `app_en.arb` is the template (source language). Other locales as `app_<code>.arb` files.
3. **`l10n.yaml` at project root, with explicit non-synthetic output:**
   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_en.arb
   output-localization-file: app_localizations.dart
   output-class: AppLocalizations
   synthetic-package: false
   output-dir: lib/l10n/generated
   ```
   Generated files commit to the repo so they're greppable and IDE-navigable.
4. **Translate vs hardcode rule.** Translate every user-facing string. Don't translate brand names (unless region-varying), debug strings, log messages, error class names. The bloc-verifier agent flags any `Text('literal')` in `presentation/` unless the literal matches a project-level allowlist at `lib/l10n/_untranslated_allow.txt`.
5. **Plurals and selects use ICU MessageFormat in ARB.** Any quantity-dependent string uses `plural`; any enum-branching string uses `select`. Conditional widget code that selects between localized strings is a bloc-verifier violation — that branching belongs in ARB.
6. **Default supported locale is `en`.** Skill ships `app_en.arb` with the canonical failure_* + loading keys (from Q7). Projects add locales by creating `app_<code>.arb` and copying the keys.
7. **Initial locale resolution.** App reads `WidgetsBinding.instance.platformDispatcher.locale`; falls back to `en` if not in `AppLocalizations.supportedLocales`.
8. **Runtime locale change** via `LocaleCubit extends HydratedCubit<Locale>` registered as app-wide singleton. App wraps `MaterialApp.router(locale: ...)` in `BlocBuilder<LocaleCubit, Locale>`. Settings feature owns the language picker UI.
9. **Translation lookups happen in widgets only.** Blocs never see localized strings — they emit failure types, ARB keys, or untyped enum values. The widget layer translates via `AppLocalizations.of(context)!.foo`. For non-widget code (auth interceptor, push handler), the skill registers a single `GlobalKey<NavigatorState> appNavigatorKey` on `MaterialApp.router` and exposes a top-level `String tr(String Function(AppLocalizations)) ` helper that reads the navigator's current context. Use sparingly.
10. **Codegen integration.** `make codegen` chains `dart run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n`. The codegen-runner agent calls `make codegen` rather than either command directly.

**Generated/touched files:**
```
l10n.yaml
lib/l10n/app_en.arb
lib/l10n/_untranslated_allow.txt
lib/l10n/generated/app_localizations.dart   # gen output, committed
```

---

### 2026-05 — Loading / empty / error UI conventions

**Context.** Without canonical state-UI widgets, every feature reinvents loading/empty/error treatments and the app loses cohesion. Goal: ship a small library in `core/widgets/state/` that every page composes.

**Decisions.**

1. **Three loading flavors, pages pick by context:**
   - `page_loading.dart` — full-screen centered `CircularProgressIndicator`. Used for first-load of a single-record screen.
   - `inline_loading_bar.dart` — 3px `LinearProgressIndicator` at top of viewport. Used when previous data is still showing during a refresh.
   - `skeleton/` — `ListSkeleton`, `CardSkeleton`, and a hand-rolled `Shimmer` primitive (~40 lines, no `shimmer` package dependency). Used for lists/grids/cards during initial fetch.
2. **One canonical empty state widget.** `EmptyState({icon, title, message?, action?})`. Centered, ~60% viewport height. Strings come from `intl` keys.
3. **Four error tiers.** Picked by the question "does the user have anything to look at?" + "did the user do something just now?":
   - **Critical (full-screen `PageError`)** — initial fetch failed, no data to show. Icon + title + message + retry button.
   - **Inline (footer retry tile)** — load-more failed, prior pages still visible. Already covered in pagination.
   - **Banner (`MaterialBanner`)** — background refresh failed but cached data is valid. Dismissable.
   - **Toast (`SnackBar`)** — discrete action failed, page state unchanged. Shown via a page-level `BlocListener`.
4. **`FailureLocalizer` extension on `AppFailure`** at `lib/core/error/failure_localizer.dart`:
   ```dart
   extension FailureLocalizer on AppFailure {
     String localize(BuildContext context) => switch (this) {
       NetworkFailure() => AppLocalizations.of(context)!.failure_network,
       ServerFailure() => AppLocalizations.of(context)!.failure_server,
       UnauthorizedFailure() => AppLocalizations.of(context)!.failure_unauthorized,
       ValidationFailure() => AppLocalizations.of(context)!.failure_validation,
       CacheFailure() => AppLocalizations.of(context)!.failure_cache,
       UnknownFailure() => AppLocalizations.of(context)!.failure_unknown,
     };
   }
   ```
   Skill ships canonical ARB keys (`failure_network`, `failure_server`, etc.) in `lib/l10n/app_en.arb`. Projects override copy by editing their ARB files; the keys are stable.
5. **Retry is a `VoidCallback`.** `PageError({required this.onRetry, ...})`. Call sites wire it to `() => context.read<XxxBloc>().add(const XxxRetryRequested())`. The widget never reads any specific bloc.
6. **Snackbar/banner side effects fire from a page-level `BlocListener`.** The listener watches the page's bloc and calls `ErrorSnackbar.show(context, failure)` or `ErrorBanner.show(context, failure)` from the helpers. Helpers wrap `ScaffoldMessenger.of(context).showSnackBar(...)`.
7. **Skeletons respect `MediaQuery.disableAnimations`** so flutter_test goldens are deterministic. Skeletons wrap their content in `Semantics(label: AppLocalizations.of(context)!.loading)` so screen readers announce "Loading" instead of empty boxes.

**Generated layout:**
```
lib/core/widgets/state/
├── page_loading.dart
├── inline_loading_bar.dart
├── empty_state.dart
├── page_error.dart
├── error_banner.dart
├── error_snackbar.dart
└── skeleton/
    ├── list_skeleton.dart
    ├── card_skeleton.dart
    └── shimmer.dart

lib/core/error/
└── failure_localizer.dart

lib/l10n/app_en.arb           # ships with failure_* and loading keys
```

---

### 2026-05 — Pagination contract

**Context.** Endless-scroll lists show up in nearly every app. Without a canonical shape, every feature reinvents page state, infinite-scroll triggers, and retry UX.

**Decisions.**

1. **Generic `Page<T>` carries both cursor and offset.** Server API determines which is populated; the repo doesn't force a choice on the skill.
   ```dart
   final class Page<T> extends Equatable {
     const Page({required this.items, required this.hasMore, this.nextCursor, this.nextOffset});
     final List<T> items;
     final bool hasMore;
     final String? nextCursor;
     final int? nextOffset;
     @override List<Object?> get props => [items, hasMore, nextCursor, nextOffset];
   }
   ```
   Lives at `lib/core/pagination/page.dart`. Mandatory.
2. **Repos return `Future<Result<Page<T>, AppFailure>>`** for paginated endpoints. The repo impl translates whichever pagination shape the server uses into `Page<T>`.
3. **State shape: sealed hierarchy with shared `items / hasMore / cursor` base.** Items already loaded must remain visible during `loadMore` and during error.
   ```dart
   sealed class FeedState extends Equatable { ... base fields ... }
   final class FeedInitial extends FeedState { ... }
   final class FeedLoading extends FeedState { ... }              // first page
   final class FeedLoaded extends FeedState { ... }
   final class FeedLoadingMore extends FeedState { ... }
   final class FeedError extends FeedState { ... ; final AppFailure failure; }
   ```
4. **Auto-trigger near scroll bottom.** Skill ships `lib/core/widgets/paginated_sliver.dart` — a `SliverList` wrapper that fires `onLoadMore()` when within ~3 items of the end (configurable). Feature pages plug it into a `CustomScrollView` and dispatch `LoadMoreRequested`.
5. **`LoadMoreRequested` handler uses `droppable()`** transformer. Concurrent triggers from rapid scroll are dropped while one is in flight.
6. **Failed `loadMore` keeps first pages visible** and shows a "Couldn't load more — tap to retry" tile at the end. Implemented as a footer item in `PaginatedSliver<T>` shown when state is `FeedError` and `state.items.isNotEmpty`. First-page failure is full-screen error (handled by the Q7 conventions, decided next).
7. **Pull-to-refresh is a separate event `FeedRefreshed`** on the same bloc, transformer `restartable()`. Resets `cursor`, fetches page 1, replaces `items`. The `RefreshIndicator` widget wraps the scroll view at page level.

**Generated layout:**
```
lib/core/pagination/
└── page.dart                    # Page<T>

lib/core/widgets/
└── paginated_sliver.dart        # auto-trigger sliver wrapper, retry footer
```

Each feature with pagination provides its own bloc, state hierarchy, and page widget that wires `PaginatedSliver<T>` to its bloc.

---

### 2026-05 — Canonical formz pattern

**Context.** `formz` is in the locked stack but the form-bloc shape, validation timing, and server-error round-trip were unspecified. Without a single canonical shape, every feature's form invents its own.

**Decisions.**

1. **Cubit by default; promote to Bloc only when a field needs debounce or async cross-validation** (e.g., username availability check, search-as-you-type). Matches the existing bloc-vs-cubit heuristic.
2. **Single-class state with `FormzSubmissionStatus`** — not a sealed hierarchy. Shape:
   ```dart
   final class LoginState extends Equatable {
     const LoginState({
       this.email = const EmailInput.pure(),
       this.password = const PasswordInput.pure(),
       this.status = FormzSubmissionStatus.initial,
       this.errorMessage,
     });
     final EmailInput email;
     final PasswordInput password;
     final FormzSubmissionStatus status;
     final String? errorMessage;
     bool get isValid => Formz.validate([email, password]);
     // hand-written copyWith
     @override List<Object?> get props => [email, password, status, errorMessage];
   }
   ```
   **This is the only documented exemption from the "every state is a sealed hierarchy" rule.** The exemption applies whenever a state class contains a `FormzSubmissionStatus` field. The bloc-verifier agent must skip rule 3 (sealed-hierarchy) for these classes; rules 1, 2, 4, 5 still apply.
3. **Validation timing: pure-vs-dirty.** `FormzInput.pure(value)` while the field has never been touched, `FormzInput.dirty(value)` after the first change. Inputs render their error only when `displayError != null`, which `formz` already gates on `isPure == false`. No focus-tracking, no submit-only validation.
4. **Server-side validation errors round-trip into individual fields.** The repository returns `Failure(ValidationFailure(fieldErrors: {'email': 'already taken'}))`. The form bloc reads `fieldErrors` and rebuilds the affected `FormzInput`s as `dirty(value, customError: '...')`. Every `FormzInput` subclass in this skill must support a `customError` constructor parameter that takes precedence over its built-in validators when set.
5. **Submission flow uses `droppable()` and a `_applyServerErrors` helper:**
   ```dart
   on<LoginSubmitted>(_onSubmitted, transformer: droppable());

   Future<void> _onSubmitted(LoginSubmitted e, Emitter<LoginState> emit) async {
     if (!state.isValid) return;
     emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
     final result = await _repo.signIn(email: state.email.value, password: state.password.value);
     switch (result) {
       case Success():
         emit(state.copyWith(status: FormzSubmissionStatus.success));
       case Failure(:final error):
         emit(_applyServerErrors(state, error)
             .copyWith(status: FormzSubmissionStatus.failure));
     }
   }
   ```
6. **`FormzInput` subclasses live in `lib/features/<feature>/presentation/bloc/inputs/` by default.** They migrate to `lib/core/forms/inputs/` on the second feature that uses them — never pre-emptively.
7. **Validation messages are `intl` keys, not hardcoded strings.** When an input is promoted to `core/forms/inputs/`, its error enum maps to ARB keys; the page's `displayError` lookup runs the lookup against the current locale.
8. **`AppFailure.ValidationFailure` gains an optional `Map<String, String> fieldErrors` field** (alongside its existing message). Data sources translate server validation responses into `ValidationFailure` with this map populated. Mandatory shape — every project's `failures.dart` template includes it.

**When to revisit.** If a project ever needs cross-field validation that fires on every change (e.g., "passwords match" updating a third indicator field), promote that form to `Bloc` with `restartable()` and document the pattern in the project's MEMORY.

---

### 2026-05 — Logging + observer (minimal surface)

**Context.** `logger` is in the locked stack but the rules around what gets logged, at what verbosity per flavor, and how state contents leak into logs were unspecified.

**Decisions.**

1. **Per-flavor verbosity** lives on `FlavorConfig.logLevel`:
   - `dev` → verbose (state-type changes, request/response bodies with `Authorization` redacted).
   - `prod` → minimal (warnings + errors only; never state contents; never request/response bodies; method + URL + status + duration only).
   - `staging` (only when a project introduces it) → between the two; project decides.
2. **`AppBlocObserver` shape — minimal:**
   - `onError`: always log via `AppLogger.error`. **No `ErrorReporter` interface.** When Sentry is added (Q10), an inline `if (Sentry.isEnabled) Sentry.captureException(...)` is added to this method. No abstraction layer.
   - `onChange`: log state TYPE only (`'AuthBloc: AuthInitial → AuthAuthenticated'`). No state contents. Logged at `info`.
   - `onTransition`: not overridden. Default behavior (calls `onChange`) is sufficient.
   - `onCreate` / `onClose`: not overridden. Too noisy to log routinely.
3. **`AppLogger`** at `lib/core/logging/app_logger.dart` wraps the `logger` package and exposes `trace / debug / info / warn / error(message, [error, stack])`. Singleton in DI; `FlavorConfig.logLevel` decides cutoff. The wrapper exists so the rest of the codebase imports `AppLogger`, never `Logger` directly — single point of swap if we ever change logging packages.
4. **Dio request/response logging is a hand-rolled interceptor** at `lib/core/network/logging_interceptor.dart`. ~80 lines. No `talker_dio_logger` / `pretty_dio_logger` dependency. Dev: full request/response with header + body redaction (`Authorization`, anything matching common token field names). Prod: method + URL + status + duration only.
5. **`main.dart` gains three lines** after `configureDependencies(config)`:
   ```dart
   Bloc.observer = getIt<AppBlocObserver>();
   FlutterError.onError = (details) =>
       getIt<AppLogger>().error('FlutterError', details.exception, details.stack);
   PlatformDispatcher.instance.onError = (error, stack) {
     getIt<AppLogger>().error('PlatformDispatcher', error, stack);
     return true;
   };
   ```
   No `ErrorReporter` indirection. Direct `AppLogger.error` call. Sentry hook (Q10) goes inline next to it when added.

**Why no `ErrorReporter` interface.** The interface would only buy a clean swap point for "Sentry is on / off." That's a 2-line conditional in `onError`. The interface costs a file, a default impl, a Sentry impl, and DI registration to save 2 lines. Net negative.

**When to revisit.** If the conditional grows past 5 lines (e.g., we add Datadog AND Sentry AND Crashlytics), refactor the conditional into a small `_reportError` helper inside the observer. Promote to an interface only if a third destination shows up.

---

### 2026-05 — Cross-feature reactions: BlocListener at App root (supersedes Q3 logout point 6)

**Context.** The earlier Q3 entry locked "user-scoped blocs subscribe to `AuthBloc.stream` and self-clear on `AuthUnauthenticated`." After verifying against bloclibrary.dev's architecture page and the DCM `avoid-passing-bloc-to-bloc` rule, that pattern is **explicitly disallowed by official BLoC guidance** — "no bloc should know about any other bloc."

**Decision.** Two patterns for cross-feature reactions, picked by where the trigger originates.

1. **Default — `MultiBlocListener` at the App widget root.** When the trigger is a state change in another bloc, the bridge lives in the presentation layer. One App-root file owns every cross-feature reaction. `CartBloc` never imports `AuthBloc`; it just receives a `CartCleared` event dispatched by the App-root listener.
2. **Only when non-bloc code is the source — reactive repository.** When the trigger does not originate in a bloc (e.g., the Dio auth interceptor flips session to signed-out on refresh failure), the relevant repository owns a broadcast `Stream` and that feature's own bloc subscribes to its own repository. Other features still use pattern 1.

**`AuthRepository` keeps its `Stream<AuthStatus>`** specifically because the auth interceptor (in `core/network/`) is non-bloc code and needs a way to push session state without knowing about any bloc. **Only `AuthBloc` subscribes to `AuthRepository.status`.** No other bloc subscribes to `AuthRepository` directly. Cross-feature reactions like "logout → clear cart" route through the App-root `BlocListener<AuthBloc, AuthState>`.

**Bloc-verifier agent gains four new rules.** Flag any of:
- A bloc taking another bloc in its constructor.
- `<otherBloc>.stream.listen(...)` inside a bloc.
- `<otherBloc>.add(...)` from inside a bloc.
- A bloc subscribing to another feature's repository (allowed only for the bloc that owns that repository).

**Supersedes.** Point 6 of the auth + token refresh entry below ("Logout cleanup is decentralized via per-bloc subscriptions"). The new logout cleanup rule is: `AuthBloc` emits `AuthUnauthenticated`, `App` widget's `MultiBlocListener` dispatches the appropriate `XxxCleared` events to every user-scoped bloc.

**Sources.**
- [Architecture | Bloc — bloclibrary.dev](https://bloclibrary.dev/architecture/)
- [avoid-passing-bloc-to-bloc | DCM](https://dcm.dev/docs/rules/bloc/avoid-passing-bloc-to-bloc/)
- [Blocs with Reactive Repository — Sandro Lovnički, Flutter Community](https://medium.com/flutter-community/blocs-with-reactive-repository-5fd440d3b1dc)

---

### 2026-05 — Auth + token refresh contract

**Context.** Auth is the most failure-prone subsystem in any app. Every project this skill touches needs the same shape so concurrency bugs, layering violations, and "logout didn't clear X" regressions don't recur.

**Decisions.**

1. **Refresh strategy: reactive only.** On `401`, the auth interceptor refreshes the token and retries the original request. If refresh also fails, logout. No proactive expiry checks, no JWT decoding, no timers.
2. **Refresh logic lives in a Dio `QueuedInterceptorsWrapper`** at `lib/core/network/auth_interceptor.dart`. `QueuedInterceptors` is mandatory — concurrent in-flight `401`s must queue behind a single refresh call, not fire N parallel refreshes.
3. **`TokenStorage` is the shared abstraction** at `lib/core/network/token_storage.dart`. It wraps `flutter_secure_storage` with `readAccess / readRefresh / write({access, refresh}) / clear`. Both the interceptor and `AuthRepositoryImpl` depend on `TokenStorage`. The interceptor never imports a feature.
4. **Refresh API call is a raw `core/network/auth_api.dart` client**, not a feature repo. Keeps the interceptor's dependency surface flat — interceptor never reaches into `features/`.
5. **`AuthBloc` is app-wide singleton (`registerLazySingleton`)**, lives in `lib/features/auth/`, extends `HydratedBloc` so cold-start auth state is read from disk before the router's redirect runs. State hierarchy: `AuthInitial | AuthAuthenticated(User user) | AuthUnauthenticated | AuthError(AppFailure failure)`. No `AuthLoading` state — login-form loading lives in `LoginBloc` (feature-scoped factory).
6. **Logout cleanup is decentralized.** Each user-scoped bloc subscribes to `AuthBloc.stream` (via DI-injected `AuthBloc`) and clears its own state on `AuthUnauthenticated`. There is no central `LogoutObserver` registry. `AuthBloc.signOut` only calls `TokenStorage.clear()` and emits `AuthUnauthenticated` — every other bloc reacts.
7. **Single account per app.** `TokenStorage` holds exactly one `(access, refresh)` pair. Multi-account is a per-project deviation and must be recorded in that project's MEMORY before being implemented.
8. **Tokens are opaque strings.** Never decode JWTs. User identity comes from a `GET /me` call after login (or after refresh, if the user was warm-restored from disk and the cached `User` is older than N minutes — N decided per project).
9. **Generated layout for the auth feature:**

```
lib/core/network/
├── dio_client.dart          # configures Dio with all interceptors
├── auth_interceptor.dart    # QueuedInterceptorsWrapper(TokenStorage, AuthApi)
├── token_storage.dart       # wraps flutter_secure_storage
└── auth_api.dart            # raw refresh-token POST only

lib/features/auth/
├── data/
│   ├── datasources/auth_remote_data_source.dart
│   ├── models/user_model.dart                    # @JsonSerializable
│   └── repositories/auth_repository_impl.dart    # ctor: AuthRemoteDataSource, TokenStorage
├── domain/
│   ├── entities/user.dart                        # pure Dart
│   └── repositories/auth_repository.dart         # abstract
└── presentation/
    ├── bloc/                                     # HydratedBloc, app-wide singleton
    ├── pages/login_page.dart
    └── widgets/
```

10. **Why decentralized logout.** Matches the skill's existing rule: no direct bloc-to-bloc calls. Each bloc owning its own reset gives the cleanest dependency graph; the `AuthBloc.stream` subscription is the same pattern used elsewhere in this skill for cross-feature reactions.

**When to revisit.** If a project ever needs multi-account, redesign that project's auth and record it. If logout cleanup ever stops being reliable (a bloc forgot to subscribe), the bloc-verifier agent gets a new rule that flags any `HydratedBloc` not subscribing to `AuthBloc` — but only after that incident actually happens.

---

### 2026-05 — `main.dart` shape (inline init, no bootstrap.dart)

**Context.** Path A removed multiple entry points, so there's no longer a need for a shared `bootstrap()` function. Init code lives inline in `main()`. Day-one main is intentionally minimal — observer, error reporter, Sentry, and orientation lock are added later only when there's a concrete reason.

**Decision.** Every project's `lib/main.dart` follows this shape:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/injection.dart';
import 'core/env/flavor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  final config = FlavorConfig.byName(flavorName);

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );

  await configureDependencies(config);

  runApp(const App());
}
```

**Rules.**
- The `kIsWeb` branch is mandatory — `path_provider` does not work in browsers; `HydratedStorageDirectory.web` is the documented fallback for web targets.
- `configureDependencies` takes `FlavorConfig` so features inject the typed config rather than reading raw `--dart-define` values.
- `Bloc.observer` registration, `FlutterError.onError`, `PlatformDispatcher.instance.onError`, Sentry init, orientation lock — all of these are added by future questions when their motivating concern shows up. Do not add stubs now.

---

### 2026-05 — Path A flavors (supersedes the earlier flavorizr-mandatory decision below)

**Context.** The earlier entry locked `flutter_flavorizr` as a base dev dependency and made native gradle/iOS flavors mandatory. After grilling, that conflicted with a hard requirement: bare `flutter run` and `flutter run --release` must work with no flags on every platform (Android, iOS, web, macOS, Windows, Linux). Once gradle product flavors exist on Android, bare `flutter run` errors because Gradle generates `assembleDevDebug`/`assembleProdDebug` instead of `assembleDebug`. Flutter has no `defaultFlavor` mechanism. Aliasing tasks in Gradle is a fragile hack that breaks across Flutter versions.

**Decision (Path A).** Drop native flavors from the base. Use Dart-side flavors only.

1. `flutter_flavorizr` moves back to `references/situational-packages.md`. **Not** in the base `pubspec.yaml`.
2. Flavor selection happens via `--dart-define=FLAVOR=<name>`, with `defaultValue: 'prod'` so bare `flutter run` and `flutter run --release` always run prod.
3. Single `lib/main.dart`. No per-flavor entry-point files. No `bootstrap.dart` — the init code lives inline in `main()`.
4. `lib/core/env/flavor.dart` defines `enum Flavor { dev, prod }` (project may add more) and a `FlavorConfig` selected by name. Public config (base URL, log level) is hard-coded per flavor in code; secrets (Sentry DSN, third-party keys) come in via additional `--dart-define`s.
5. All six platforms behave identically — `--dart-define` works everywhere; bare `flutter run` works everywhere.
6. **Trade-off accepted:** dev and prod cannot install side-by-side on the same device (one bundle ID, one app icon). When a specific project hits the 5% case where side-by-side install is required, that project opts into `flutter_flavorizr` via the situational reference, accepts that `make run` becomes its canonical command, and records the deviation in its own MEMORY entry. The skill default does not pay that complexity.
7. The `/configure-flutter-app` slash command still exists, but its scope is now: write `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`, `lib/app/`, `lib/core/env/`, `Makefile`, `.vscode/launch.json`. It does NOT run flavorizr by default. It asks the user to name the flavors (default offered: `dev` and `prod`) and to provide the bundle ID prefix (`com.example.<app>` shown as placeholder, never assumed). It runs `flutter_launcher_icons` and `flutter_native_splash` once (single icon, single splash), not per-flavor.
8. **Smoke test for `/configure-flutter-app`:** `flutter analyze` + `flutter test` + `flutter build apk --debug` + `flutter build ios --no-codesign --debug` + `flutter build web`. The three builds catch base-pubspec issues before CI does.

**Supersedes.** The 2026-05 "Flavors are mandatory" entry below. Treat this entry as authoritative; that earlier entry is kept for history.

---

### 2026-05 — Flavors are mandatory; `/configure-flutter-app` owns setup

**Context.** Every Flutter app needs at minimum a dev / prod separation: different API base URLs, different bundle IDs so both can install side-by-side, different app icons so the home screen tells you which is which, different Sentry DSN. Doing this by hand per project is error-prone; flavorizr automates 80% but breaks iOS storyboard linking and scheme generation.

**Decision.**

1. **`flutter_flavorizr` is now a locked dev dependency** (move from situational → base). Every project this skill touches uses it.
2. **Flavors are not hardcoded.** The slash command `/configure-flutter-app` asks the user at runtime which scheme they want:
   - `dev | prod` (default)
   - `dev | staging | prod`
   - custom — user names the flavors.
3. **Bundle ID prefix is asked at runtime.** No assumed prefix. The prompt shows `com.example.<app>` as a placeholder. Dev/staging variants append `.dev` / `.staging`.
4. **`flutter run` (bare) is not the canonical command.** Once gradle flavors exist, `flutter run` requires `--flavor`. The skill's run contract is **the generated `Makefile`**: `make run`, `make run-dev`, `make build-prod`, `make build-dev`, `make codegen`, `make test`, `make analyze`. The default flavor is whichever the user designated as production at setup time.
5. **`/configure-flutter-app` is idempotent and end-to-end.** It owns the entire app-init pipeline:
   - Asks: flavor scheme + bundle ID prefix + app display name.
   - Writes locked `pubspec.yaml`, `analysis_options.yaml`, `flavorizr.yaml`.
   - Runs `flutter pub get` → `dart run flutter_flavorizr`.
   - Patches the known iOS breakage flavorizr leaves behind: re-links `LaunchScreen.storyboard` in each xcconfig, fixes `Info.plist` `CFBundleDisplayName` to `$(APP_DISPLAY_NAME)`, registers schemes in `xcschememanagement.plist`, repairs `Runner.xcscheme` xcconfig pointers.
   - Runs `flutter_launcher_icons` per flavor (dev gets a corner badge so the home-screen icon is obviously dev).
   - Runs `flutter_native_splash:create` per flavor (dev gets a different background color so the splash is obviously dev).
   - Generates `lib/main.dart` (delegates to prod entry), `lib/main_<flavor>.dart` per flavor, `lib/app/bootstrap.dart`, `lib/core/env/flavor.dart`, `lib/core/env/flavor_config.dart`.
   - Generates `Makefile` and `.vscode/launch.json` with all flavor profiles.
   - Smoke test: `flutter analyze` + `flutter test` + `flutter build apk --flavor <prod> --debug` + `flutter build ios --flavor <prod> --no-codesign --debug`. The two builds are non-negotiable — they're the only thing that catches flavorizr-induced gradle/xcconfig breakage before CI.
   - Bails cleanly on any failure with a numbered remediation list — never leaves the project half-configured.
6. **`AppConfig` is keyed by flavor in code, not by env file.** Public config (base URL, log level, feature-flag defaults) lives in `lib/core/env/flavor_config.dart` as `const FlavorConfig` records selected by flavor. Secrets (Sentry DSN, third-party API keys) come in via `--dart-define` and are read into the same record at startup. No `envied` package — keeps codegen surface to `json_serializable` only.

**Open issues that the slash command must handle.**
- iOS storyboard re-link after flavorizr (current: needs manual edit; slash command must automate).
- App icon source PNG: slash command asks for a path or generates a placeholder; never silently uses a default that ships with the skill.
- Apple development team / signing: cannot be automated; slash command prints the required Xcode steps as a closing checklist.

**When to revisit.** If a project hits a flavor pattern that needs more than `dev | staging | prod` regularly (e.g., per-region builds), the slash command's "custom" path already supports it — no skill change needed. If `--dart-define` becomes painful for ten+ secrets, reconsider `envied` via a fresh MEMORY entry.

---

## How to update this skill over time

1. Open this file, append a new dated entry under "Decision log" describing what changed and why.
2. If the change supersedes an earlier decision, reference the earlier entry by date.
3. Update `SKILL.md` and any affected templates to reflect the new decision.
4. Bump `version` field in `SKILL.md` frontmatter when a meaningful change ships.

The MEMORY file is the spine. SKILL.md and templates are the limbs.
