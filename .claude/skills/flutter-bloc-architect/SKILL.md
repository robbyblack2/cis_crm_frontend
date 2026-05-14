---
name: flutter-bloc-architect
description: Robby's strict Flutter + BLoC architecture skill. Use this skill any time the user is working in a Flutter or Dart project — creating a new app, adding a feature, writing or modifying a `Bloc`, `Cubit`, repository, data source, or any state class, editing `pubspec.yaml`, working with `*.dart` files, running `flutter pub get`, configuring `go_router`, setting up `get_it` DI, writing widget or bloc tests, or designing folder structure. Trigger whenever the user mentions Flutter, BLoC, Cubit, Dart, `pubspec`, `flutter_bloc`, `hydrated_bloc`, `Equatable`, sealed state, `Result<T, F>`, `AppFailure`, repository pattern, Clean Architecture in Flutter, `go_router`, `get_it`, `formz`, `json_serializable`, or any related package. Trigger even when the user does not say "Flutter" explicitly if the file extension is `.dart`, `.yaml` in a Flutter project, or the language is Dart. Apply the locked stack and architecture rules in this file uniformly across every Flutter project this skill enters.
version: 1.9.0
---

# Flutter BLoC Architect

This skill enforces a single, consistent architecture across every Flutter app the user builds: a strict BLoC pattern, a feature-first three-layer folder structure, a typed `Result<T, F>` error contract, and a locked dependency stack. The goal is that years of Flutter projects share the same shape — knowledge accumulated in one project transfers to the next without re-deciding architecture.

The full decision history lives in `MEMORY.md`. The hard rules below are the compiled output of those decisions. When something seems ambiguous, MEMORY.md is the source of truth.

## Mission

When working in a Flutter codebase, do the following:

1. **Conform to the rules in this file before writing any code.** Read `MEMORY.md` if a question feels under-specified.
2. **Use templates from `templates/`** instead of writing structure from scratch. Templates are pre-aligned to every rule.
3. **Load reference docs from `references/` only when the user's task touches that topic.** The references are deep dives, not always-loaded context.
4. **Invoke companion agents from `agents/` for repetitive or verification work** — codegen runs, feature scaffolding, rule auditing, test running.
5. **When something is unclear, ask before guessing.** This skill is meant to be opinionated; don't drift.

## Hard rules

These rules apply to every change, in every Flutter project this skill operates in. Violations are bugs.

### Stack

The base `pubspec.yaml` is locked. Do not add packages to it without an explicit user decision and a corresponding `MEMORY.md` entry. The full list lives in `templates/pubspec.yaml`. The headline rules:

- BLoC ecosystem only for state: `flutter_bloc`, `hydrated_bloc`, `bloc_concurrency`. No Riverpod, Provider, MobX, or GetX in the same project.
- `Equatable` for value equality. No `freezed`. No hand-rolled `==` either — always extend `Equatable`.
- `get_it` for dependency injection. Manual registration in `lib/app/injection.dart`. No `injectable` codegen.
- `go_router` for routing. Never call `Navigator.push` directly. Type-safe routes via string constants in `lib/core/router/routes.dart` — no `go_router_builder` codegen.
- `dio` for HTTP. Interceptors in `lib/core/network/`. Auth refresh via `QueuedInterceptorsWrapper`.
- `formz` for form validation. Form states are single-class with `FormzSubmissionStatus` (the **only** documented exemption from the sealed-hierarchy rule).
- `json_serializable` for JSON codegen — the only codegen package in the stack.
- `flutter gen-l10n` for localization. ARB files in `lib/l10n/`. Built-in tool, not `slang`.
- `very_good_analysis` for linting.
- **Inter** is the bundled default font (variable TTF in `assets/fonts/`). Replace per project as needed.

When a project needs a non-base package (image cache, push notifications, analytics, Sentry, connectivity, feature flags, etc.), check `references/situational-packages.md` for the canonical setup, add to that project's `pubspec.yaml`, do not modify the skill template. The skill stays lean; projects opt in.

### Architecture

Three-layer feature-first. Every feature is a vertical slice in `lib/features/<feature>/`:

```
lib/features/<feature>/
├── data/
│   ├── datasources/
│   ├── models/                 # DTOs with @JsonSerializable
│   └── repositories/           # *_impl.dart — implements domain abstract repo
├── domain/
│   ├── entities/               # pure Dart, no JSON, no Flutter
│   └── repositories/           # ABSTRACT class — the contract
└── presentation/
    ├── bloc/                   # bloc_event.dart, bloc_state.dart, bloc.dart
    ├── pages/                  # route targets
    └── widgets/                # feature-local widgets
```

Shared cross-feature code lives in `lib/core/`. App-level wiring lives in `lib/app/`. The full structure is in `templates/_project_structure.md`.

Two iron rules:

1. **Dependency direction points inward toward `domain/`.** `presentation/` imports from `domain/`. `data/` implements `domain/` interfaces. `domain/` imports nothing from the other two layers. The domain layer compiles without Flutter.
2. **No feature imports another feature.** Cross-feature interaction goes through `lib/core/` (shared types, shared widgets) or via subscribing to another bloc's stream injected through DI. Never `import 'features/auth/...'` from `features/cart/`.

### Error handling

Repositories return `Future<Result<T, AppFailure>>`. They never throw. Data sources may throw `AppException`s; repositories catch them and convert to a typed `Failure<T, AppFailure>`. Bloc handlers exhaustively `switch` on the result.

The three error files in `lib/core/error/`:

- `result.dart` — `sealed class Result<T, F>` with `Success<T, F>(T data)` and `Failure<T, F>(F error)`.
- `failures.dart` — sealed `AppFailure` hierarchy: `NetworkFailure`, `ServerFailure`, `UnauthorizedFailure`, `ValidationFailure`, `CacheFailure`, `UnknownFailure`.
- `exceptions.dart` — sealed `AppException` hierarchy: `ServerException`, `NetworkException`, `CacheException`, `UnauthorizedException`, `ValidationException(fieldErrors)`.

Templates for all three are in `templates/core/error/`. Copy as-is.

Detailed patterns and the full repository-impl pattern are in `references/error-handling.md` — load when adding a new repo or when a bloc handler needs more than basic error mapping.

### State classes

Every state class follows all five rules:

1. `extends Equatable`.
2. Annotated `@immutable` (from `package:flutter/foundation.dart`).
3. Part of a `sealed` hierarchy.
4. All constructors are `const`.
5. `copyWith` is hand-written — use the sentinel pattern when nullable fields need "set to null" support (see `templates/feature/domain/entities/example_entity.dart` for the canonical sentinel implementation).

**Single documented exemption:** form states that contain a `FormzSubmissionStatus` field are single-class, not sealed. `FormzSubmissionStatus` is itself a state machine — wrapping it in a second sealed hierarchy duplicates information. Bloc-verifier skips rule 3 for these classes; rules 1, 2, 4, 5 still apply.

Default state shape per feature: `Initial | Loading | Loaded | Error`, named for the feature (e.g., `AuthInitial | AuthLoading | AuthAuthenticated | AuthUnauthenticated | AuthError`).

`props` getter lists every field. Adding a field means updating `props`. The bloc-verifier agent flags missing fields.

For deeper guidance on union shapes, the formz exemption, and the canonical pagination shape, load `references/state-design.md`.

### DI graph

`get_it` registration lives in `lib/app/injection.dart`. Order is bottom-up:

1. Leaves (no deps) — `SecureStorage`, `SharedPreferences`.
2. Data providers — `Dio` with interceptors.
3. Data sources — concrete impls.
4. Repositories — abstract interface registered to concrete impl.
5. Blocs.

App-wide blocs are singletons (`registerLazySingleton`). Feature blocs are factories (`registerFactory`).

Widgets reach blocs via `BlocProvider`/`MultiBlocProvider`:
- `BlocProvider.value(value: getIt<XxxBloc>())` for singletons.
- `BlocProvider(create: (_) => getIt<XxxBloc>())` for factories.

Template: `templates/app/injection.dart`. Patterns: `references/di-patterns.md`.

### Repository orchestration

Blocs may take **multiple repositories** in their constructor and orchestrate them directly in event handlers. There is no separate "use case" layer in this stack — that abstraction is overhead for typical app-scale flows. When a bloc needs to combine two or three repos (e.g., a checkout flow calling cart + payment + order), inject all three and write the orchestration in the handler with sequential `Result` checks. See `references/architecture.md` for the canonical multi-repo bloc pattern.

### Repository → data source rule

Repositories never depend on `core/` data providers (`Dio`, `SecureStorage`, `SharedPreferences`) directly. A repository's constructor takes only feature-scoped data sources (`XxxRemoteDataSource`, `XxxLocalDataSource`). Each data source uses one or more `core/` providers internally. This keeps repos focused on business logic + failure mapping; data sources own raw I/O. The bloc-verifier agent flags any repo impl whose constructor takes a `core/`-level provider.

### Bloc vs Cubit

- **`Cubit`** for load-only screens — no concurrent flows, no debounced search, no multi-step interactions. Method calls in, states out.
- **`Bloc`** for multi-action screens — login with debounced validation, search-as-you-type, forms with multiple async actions, file uploads.

If unsure, default to `Cubit` and upgrade to `Bloc` when concurrency rules show up. See `references/bloc-vs-cubit.md`.

### Hydrated state

Use `HydratedBloc` for state that must survive app restarts: auth, theme, onboarding-completed, cart, user preferences. Implement `toJson`/`fromJson` on the state class. See `references/hydrated-bloc.md`.

### Concurrency transformers

Every event handler that fires from user input must declare a `bloc_concurrency` transformer:

- `droppable()` — submit buttons.
- `restartable()` — search-as-you-type.
- `sequential()` — ordered ops (file uploads).
- `concurrent()` — independent ops.

Pattern in `templates/feature/presentation/bloc/example_bloc.dart`.

### UI binding

- `BlocBuilder` with `buildWhen` for granular rebuilds.
- `BlocListener` for one-shot side effects (snackbars, navigation, dialogs).
- `BlocConsumer` only when both are needed in the same widget.
- Avoid `context.watch<MyBloc>()` outside `BlocBuilder` (no `buildWhen` escape hatch).

### Cross-feature reactions

**No bloc imports another bloc, ever.** Per official BLoC team guidance ([bloclibrary.dev/architecture](https://bloclibrary.dev/architecture/) and DCM `avoid-passing-bloc-to-bloc`), "no bloc should know about any other bloc." Two allowed channels:

1. **Default — `MultiBlocListener` at the App widget root.** When a state change in one bloc must trigger an event in another, the bridge lives in `lib/app/app.dart`. One file owns all cross-feature reactions.
2. **Reactive repository — only when a non-bloc source pushes the trigger** (e.g., the auth refresh interceptor). The relevant repository owns a broadcast `Stream`; that feature's own bloc subscribes to its own repo. Other features still react via channel 1.

Bloc-verifier flags any bloc taking another bloc in its constructor, any `<otherBloc>.stream.listen(...)`, any `<otherBloc>.add(...)` from another bloc, or any cross-feature repository subscription.

### Flavors

**Path A — Dart-side flavors only.** No `flutter_flavorizr`, no Android product flavors, no iOS schemes per flavor. Flavor selection is `--dart-define=FLAVOR=<name>` with `defaultValue: 'prod'`, so bare `flutter run` and `flutter run --release` always run prod. Works identically on all six platforms (Android, iOS, web, macOS, Windows, Linux).

`FlavorConfig` lives in `lib/core/env/flavor.dart` with public config (base URL, log level) hardcoded per flavor. Secrets (Sentry DSN, API keys) come in via additional `--dart-define`s.

**Trade-off accepted:** dev and prod cannot install side-by-side on one device. When a project genuinely needs that, opt into `flutter_flavorizr` via the situational reference and accept that `make run` becomes the canonical run command.

### Routing

`go_router` only. Auth-gated routes use a `redirect` callback that reads `AuthBloc.state`. Route paths come from constants in `lib/core/router/routes.dart` — no `go_router_builder` codegen, no raw string paths in widget code. Template: `templates/core/router/app_router.dart`. Deeper patterns: `references/routing.md`.

Redirect priority chain (when all are present): force-upgrade → onboarding → auth → no redirect.

### Adaptive UI

Material 3 only (`useMaterial3: true`). Dark and light themes mandatory from day one. Every page-level layout uses `LayoutBuilder` against the canonical breakpoints in `lib/core/responsive/breakpoints.dart` (`compact 600`, `medium 840`, `expanded 1200`). The shipped `AdaptiveScaffold` switches between `NavigationBar` (compact), `NavigationRail` (medium), and `NavigationDrawer` (expanded) automatically.

Accessibility is non-negotiable: every `IconButton` has a tooltip; every non-decorative `Image` has a `semanticLabel`; minimum 48dp tap targets; never override `MediaQuery.textScaler`.

### Performance hygiene

Performance is a first-class concern, not a "we'll profile later" afterthought. Five baseline rules — verifier-enforced where mechanical, manually applied where judgment is required:

1. **`const` everywhere it compiles.** Enforced by `very_good_analysis` (`prefer_const_constructors`, `prefer_const_constructors_in_immutables`, `prefer_const_declarations`, `prefer_const_literals_to_create_immutables`).
2. **`BlocBuilder.buildWhen` is mandatory** for any builder whose widget tree contains more than a single Text/Icon. For widgets that read one slice of state, use `BlocSelector<XBloc, XState, T>` — it skips the rebuild if the selected slice didn't change.
3. **`RepaintBoundary`** wraps widgets that **repaint frequently and independently of their parent** — specifically: Lottie animations, custom paints, video players, shimmer placeholders, animated icons, charts. NOT a blanket "wrap every widget" rule — `RepaintBoundary` adds a compositing layer + GPU memory; speculative wrapping is a regression. The shipped `core/widgets/state/skeleton/shimmer.dart` is already wrapped.
4. **`ListView.builder` for variable-length lists.** Bloc-verifier flags `ListView(children: [...])` with more than ~5 children. Same rule for `GridView`, `Column` containing `for (...)` over a list, and any custom scroller.
5. **`Image.network` requires `cacheWidth` and/or `cacheHeight`** sized to the actual render dimensions. Decoding a 4000×3000 photo into a 100×100 thumbnail wastes ~50 MB of memory per image. Verifier flags missing cache dimensions on `Image.network` and `Image.asset` for assets larger than 256×256.

Deeper patterns (BlocSelector worked examples, AnimatedBuilder with the `child:` skip-trick, DevTools "Highlight Repaints" overlay, image cache sizing rules of thumb, when NOT to use `RepaintBoundary`): `references/performance.md`.

### main.dart shape

Single `lib/main.dart`. No `bootstrap.dart`. Inline init:

```dart
WidgetsFlutterBinding.ensureInitialized();
const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
final config = FlavorConfig.byName(flavorName);
HydratedBloc.storage = await HydratedStorage.build(
  storageDirectory: kIsWeb
      ? HydratedStorageDirectory.web
      : HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
);
await configureDependencies(config);
Bloc.observer = getIt<AppBlocObserver>();
FlutterError.onError = (d) => getIt<AppLogger>().error('FlutterError', d.exception, d.stack);
PlatformDispatcher.instance.onError = (e, s) { getIt<AppLogger>().error('PlatformDispatcher', e, s); return true; };
runApp(const App());
```

The `kIsWeb` branch is mandatory — `path_provider` doesn't work in browsers.

### Auth + token refresh

- `AuthRepository` exposes `Stream<AuthStatus> get status` (broadcast).
- Auth interceptor at `lib/core/network/auth_interceptor.dart` extends **`QueuedInterceptorsWrapper`** — concurrent 401s queue behind one refresh.
- `TokenStorage` at `lib/core/network/token_storage.dart` is the only place tokens are read/written. Both interceptor and `AuthRepositoryImpl` depend on it.
- `AuthBloc` is `HydratedBloc`, app-wide singleton, subscribes to its OWN `AuthRepository.status`. Other features react via App-root listener.
- Tokens are opaque strings — never decode JWT. User comes from `GET /me`.
- Single account per app.

### Logging + observer

- `AppLogger` at `lib/core/logging/app_logger.dart` wraps the `logger` package. Level read from `FlavorConfig.logLevel` (dev = trace; prod = warning).
- `AppBlocObserver` at `lib/core/observability/app_bloc_observer.dart` logs state TYPE only on `onChange` (never contents) and forwards `onError` to `AppLogger.error`. Sentry hooks are inline conditionals — no `ErrorReporter` interface.
- `LoggingInterceptor` at `lib/core/network/logging_interceptor.dart` strips request/response bodies + sensitive headers in prod; full payload (with header redaction) in dev.

### Forms (formz)

- Cubit by default; promote to Bloc only when a field needs debounced async validation.
- State is single-class with `FormzSubmissionStatus` (the documented exemption).
- Validation: `FormzInput.pure` until first change; then `FormzInput.dirty(value, customError?)`. Errors render only when `displayError != null`.
- Server-side validation errors round-trip via `ValidationFailure(fieldErrors: {...})` → form bloc rebuilds each field with `customError`.
- Submit handler uses `droppable()`.

### Pagination

- Generic `Page<T>` at `lib/core/pagination/page.dart` carries `items / hasMore / nextCursor / nextOffset`. Repos populate whichever fields the server uses.
- State is a sealed hierarchy with shared `items / hasMore / cursor` base (`FeedInitial | FeedLoading | FeedLoaded | FeedLoadingMore | FeedError`). Items stay visible across loading-more and error.
- `PaginatedSliver<T>` widget at `lib/core/widgets/paginated_sliver.dart` auto-fires `onLoadMore` near scroll bottom and renders the retry-tile footer on error.
- `LoadMoreRequested` uses `droppable()`. `FeedRefreshed` uses `restartable()`.

### Loading / empty / error UI

Reusable widgets at `lib/core/widgets/state/`:

- Loading: `PageLoading` (spinner), `InlineLoadingBar` (top linear), `skeleton/{ListSkeleton, CardSkeleton, Shimmer}` (skeletons respect `MediaQuery.disableAnimations` and carry `Semantics(label: 'Loading')`).
- `EmptyState` — icon + title + message + optional action.
- Error tiers: `PageError` (critical), inline retry tile (handled by `PaginatedSliver`), `ErrorBanner` (background-refresh-failed), `ErrorSnackbar` (action-failed).
- `FailureLocalizer` extension on `AppFailure` at `lib/core/error/failure_localizer.dart` maps each failure subtype to its localized ARB key. Widgets call `failure.localize(context)`. Blocs never localize.

### Localization

- `flutter gen-l10n` (built-in). No `slang`.
- ARB files at `lib/l10n/app_<code>.arb`. Generated output committed at `lib/l10n/generated/`.
- Translate every user-facing string. Bloc-verifier flags `Text('literal')` in `presentation/` outside the `lib/l10n/_untranslated_allow.txt` allowlist.
- Plurals + selects use ICU MessageFormat in ARB. Conditional widget code that branches between localized strings is a violation.
- Runtime locale change via `LocaleCubit extends HydratedCubit<Locale>`. App wraps `MaterialApp.router(locale: ...)` in `BlocBuilder<LocaleCubit, Locale>`.
- Non-widget code uses the `appNavigatorKey` escape hatch: `tr((l) => l.foo)` reads the navigator's current context.

### Assets

- Folder layout: `assets/{images,icons,fonts,lottie}/`. Three build-input PNGs at `assets/` root (`launcher_icon.png`, `launcher_icon_foreground.png`, `splash.png`).
- Naming: `snake_case_lowercase` only. Density variants in `2.0x/`, `3.0x/` subfolders.
- Type-safe references: `lib/core/assets/app_assets.dart` constants. Bloc-verifier flags raw `'assets/...'` strings elsewhere.
- Icons: Material Icons cover ~80% of needs by default. SVG support (`flutter_svg`) is situational.
- Font: Inter bundled at `assets/fonts/Inter-VariableFont.ttf`. No `google_fonts` package.
- Launcher icons + native splash: `flutter_launcher_icons` + `flutter_native_splash` for all six platforms (web excluded from native splash).

### Analytics + crash reporting

- Sentry is opt-in per project via `FlavorConfig.sentryDsn`. `sentry_flutter` stays in `references/situational-packages.md`.
- PII scrubber at `lib/core/observability/sentry_scrub.dart` strips emails, IPs, cookies, request bodies; keeps stable user IDs only. Mandatory when Sentry is enabled.
- Bloc breadcrumbs carry state TYPE only — never contents.
- Sentry APM at default sample rates (0.1 prod / 1.0 dev). `sentry_dio` interceptor wired automatically.
- `AnalyticsService` interface at `lib/core/analytics/analytics_service.dart` ships with a no-op default. Projects register a real impl when they enable analytics.
- Analytics events fire from `BlocListener` widgets (App-root or page-level), never from inside bloc handlers. No PII in event properties.

### Connectivity

- `connectivity_plus` is situational. When opted in, the canonical wiring is a `ConnectivityCubit` at `lib/core/connectivity/` exposing `enum ConnectivityStatus { online, offline }` (not `HydratedCubit`).
- Offline indicator shown as a `MaterialBanner` triggered from the App-root `MultiBlocListener`.
- Repos do NOT branch on connectivity. They call, fail with `NetworkFailure`, the UI renders the failure. True offline-first is a per-project decision.

### Feature flags / remote config

- `FeatureFlagService` interface at `lib/core/flags/feature_flag_service.dart`. No-op default impl always returns hardcoded defaults from `FeatureFlags`.
- Every flag has a hardcoded default — the app must work without remote config.
- Real impl (`firebase_remote_config`, `launchdarkly_flutter_client_sdk`, etc.) is a per-project DI swap.
- Dev flavor exposes `/debug/flags` with toggle UI; overrides persist to `SharedPreferences` until cleared.

### Deep links + push notifications → routing

- `app_links` is situational. The skill ships only the Dart-side pattern.
- A single `appNavigatorKey: GlobalKey<NavigatorState>` is declared in `lib/app/app.dart` and passed to `MaterialApp.router`. Used by push handlers, auth interceptor, and the localization escape hatch.
- Push payloads carry a `route` field; handlers call `appNavigatorKey.currentContext!.go(route)`. Cold-start payload check runs in `main.dart`.

### Onboarding + force-upgrade

- `OnboardingCubit extends HydratedCubit<bool>` tracking `seenIntro`.
- Force-upgrade is opt-in via `FeatureFlagService` reading `min_app_version`. `AppUpdateCubit` emits `UpdateRequired | UpdateOptional | UpToDate`.
- Router redirect chain: force-upgrade → onboarding → auth → no redirect.

### Testing — TDD is non-negotiable

**Writing implementation code before its driving test exists is a violation.** This applies to new code and to changes to existing code. Bug fixes start with a failing test that demonstrates the bug. There is no exception path.

Red-green-refactor for every change. Defer to the user's overall `tdd` skill for procedural details; this section adds Flutter-specific particulars and the enforcement mechanisms.

1. **Red:** write the failing test first. For a new bloc, write `blocTest<XxxBloc, XxxState>` calls covering every event-to-state path. For a repo impl, write `test('converts NetworkException to NetworkFailure', …)` for every exception → failure branch. Run `flutter test` and confirm the new test fails for the *expected* reason (assertion mismatch or `UnimplementedError`) — not a compile error. Compile errors mean the test is missing the stub APIs needed to even compile; add them first.
2. **Green:** write the **minimum** code to make the failing test pass. Don't add fields, branches, or refactor existing code beyond what the failing test demands.
3. **Refactor:** with the bar green, tidy. Run `flutter test` after every refactor step. A refactor that turns a green test red is a bug in the refactor.

**Enforcement mechanisms (multiple, redundant):**

- **`lefthook` pre-commit hook** rejects any commit that touches files under `lib/features/**`, `lib/core/**`, or `lib/app/**` without a corresponding change under `test/`. Bypassing requires `git commit --no-verify`, which the user does not do.
- **`bloc-verifier` rule 36** flags any source file under `lib/` lacking a sibling test file at the mirrored path under `test/`. Covers blocs, cubits, repo impls, data sources, pages, services.
- **`bloc-verifier` rules 37–38** flag public bloc events / repo failure-mapping branches without a referencing test, and cubit `emit`-calling methods / page widgets without a corresponding test file.
- **CI workflow** runs `flutter test --coverage` and a "diff check" job that fails the PR if `lib/` changed without `test/` changing.
- **`feature-scaffolder`** emits **failing tests + minimum impl stubs** (returning `UnimplementedError` / `Initial`). Running `flutter test` immediately after scaffolding produces an expected red bar that the user fills in green via the loop. The scaffolder never produces a green test paired with an empty impl — that defeats the loop.

`test/` mirrors `lib/` exactly. Use `bloc_test` and `mocktail`. Templates in `templates/test/`. Loop walkthrough, layer order (entity → bloc → repo → data source → widget), and bug-fix TDD in `references/testing.md`.

Coverage target ~70%, **no hard CI gate on percentage** (gates incentivize useless tests) — but a coverage drop without a corresponding code deletion is investigated as a TDD violation in disguise. Goldens via `alchemist` (situational); integration via `patrol` (situational).

### CI / pre-commit

- `lefthook` for pre-commit hooks. Cross-platform; install with `lefthook install`. Pre-commit checks: `dart format --set-exit-if-changed` + `flutter analyze`.
- GitHub Actions workflow at `.github/workflows/ci.yaml` runs format + analyze + test on every push, plus a build job per platform the project targets. Required checks for merging to `main`: format, analyze, test.

### Linting

`analysis_options.yaml` extends `package:very_good_analysis/analysis_options.yaml`. Template: `templates/analysis_options.yaml`. No warnings in committed code.

## Files in this skill

```
flutter-bloc-architect/
├── SKILL.md                    # This file — always loaded when skill triggers.
├── MEMORY.md                   # Decision log — source of truth.
├── commands/
│   └── configure-flutter-app.md     # Idempotent end-to-end project setup.
├── templates/                  # Source files only — no build artifacts (.gitignore enforces).
│   ├── .gitignore
│   ├── analysis_options.yaml
│   ├── pubspec.yaml
│   ├── l10n.yaml
│   ├── lefthook.yml
│   ├── Makefile
│   ├── main.dart
│   ├── _project_structure.md
│   ├── .vscode/launch.json
│   ├── .github/workflows/ci.yaml
│   ├── app/
│   │   ├── app.dart                 # MultiBlocProvider + MultiBlocListener + appNavigatorKey
│   │   └── injection.dart           # configureDependencies(FlavorConfig)
│   ├── core/
│   │   ├── analytics/analytics_service.dart       # interface + NoopAnalyticsService
│   │   ├── assets/app_assets.dart
│   │   ├── env/{flavor,flavor_config}.dart
│   │   ├── error/{result,failures,exceptions,failure_localizer}.dart
│   │   ├── flags/feature_flag_service.dart        # interface + NoopFeatureFlagService
│   │   ├── logging/app_logger.dart
│   │   ├── network/{dio_client,auth_interceptor,error_interceptor,
│   │   │              logging_interceptor,token_storage,auth_api}.dart
│   │   ├── observability/app_bloc_observer.dart
│   │   ├── pagination/page.dart
│   │   ├── responsive/breakpoints.dart
│   │   ├── router/{app_router,routes,shell}.dart
│   │   ├── theme/{app_theme,app_colors,app_text_styles}.dart
│   │   └── widgets/
│   │       ├── adaptive_scaffold.dart
│   │       ├── paginated_sliver.dart
│   │       └── state/
│   │           ├── {page_loading,inline_loading_bar,empty_state,
│   │           │     page_error,error_banner,error_snackbar}.dart
│   │           └── skeleton/{shimmer,list_skeleton,card_skeleton}.dart
│   ├── feature/                # Scaffold for new features
│   │   ├── _README.md
│   │   ├── _cubit_variant/...
│   │   ├── _hydrated_variant/...
│   │   ├── data/{datasources,models,repositories}/example_*.dart
│   │   ├── domain/{entities,repositories}/example_*.dart
│   │   └── presentation/{bloc,pages,widgets}/example_*.dart
│   ├── lib/l10n/{app_en.arb,_untranslated_allow.txt}
│   └── test/{example_bloc_test,example_repository_impl_test,test_helpers}.dart
├── references/
│   ├── architecture.md
│   ├── bloc-vs-cubit.md
│   ├── di-patterns.md
│   ├── error-handling.md
│   ├── hydrated-bloc.md
│   ├── performance.md
│   ├── routing.md
│   ├── situational-packages.md
│   ├── state-design.md
│   ├── testing.md
│   └── theming.md
└── agents/
    ├── _README.md
    ├── bloc-researcher.md           # Fetches & cites official BLoC docs
    ├── bloc-verifier.md             # Audits the codebase against the rules
    ├── codegen-runner.md            # Runs build_runner + flutter gen-l10n
    ├── feature-scaffolder.md        # Generates failing tests + minimum stubs
    └── flutter-tester.md            # dart format + flutter analyze + flutter test
```

## Slash commands

| Command | What it does |
|---|---|
| `/configure-flutter-app` | One-shot, idempotent setup of an empty/created Flutter project against this skill. Asks for app name, bundle ID prefix, flavor scheme, target platforms, theme seed color, and optional features (Sentry, analytics, connectivity, feature flags, push, deep links, force-upgrade). Writes `pubspec.yaml`, `analysis_options.yaml`, the full `lib/` scaffold, `l10n.yaml`, `Makefile`, `.vscode/launch.json`, `lefthook.yml`, CI workflow, generates launcher icons + native splash, runs codegen, smoke-tests with `flutter analyze` + `flutter test` + per-platform builds. |

## When to load which reference

The references are deep dives. Loading all of them every time wastes context. Load each reference only when the task at hand actually touches that topic.

| Trigger | Load |
|---|---|
| Adding a new feature | `references/architecture.md` + `templates/feature/` |
| Designing or modifying state classes | `references/state-design.md` |
| Writing a repository or wiring errors | `references/error-handling.md` |
| Choosing between Bloc and Cubit | `references/bloc-vs-cubit.md` |
| Adding state that survives app restart | `references/hydrated-bloc.md` |
| Wiring DI for a new feature | `references/di-patterns.md` |
| Adding routes or auth-gating | `references/routing.md` |
| Setting up theme / dark mode / branding | `references/theming.md` |
| Writing tests | `references/testing.md` |
| Profiling jank, optimizing scrolls/animations, image caching | `references/performance.md` |
| User asks to add a non-base package | `references/situational-packages.md` |

## When to invoke which agent or command

| Situation | Action |
|---|---|
| User wants to set up a new Flutter project against this skill | Run `/configure-flutter-app` |
| Modified an `@JsonSerializable` class or any other annotated source, or added/changed an ARB key | `agents/codegen-runner.md` (calls `make codegen`) |
| User asks to add a new feature by name | `agents/feature-scaffolder.md` |
| Before declaring a non-trivial change "done" | `agents/bloc-verifier.md` + `agents/flutter-tester.md` |
| Tests or analyzer fail | `agents/flutter-tester.md` |
| Architectural question that needs an authoritative BLoC-team answer (before locking a new MEMORY decision, when grilling, or when reconciling community advice) | `agents/bloc-researcher.md` |

## Canonical BLoC sources

When a decision in this skill needs justification or a question needs an authoritative answer, **these are the sources of record**, in priority order. Every architectural rule in this skill traces back to one of them; when in doubt, invoke `agents/bloc-researcher.md` to fetch and cite directly.

### Tier 1 — Official BLoC documentation

- [bloclibrary.dev](https://bloclibrary.dev/) — root.
- [Architecture](https://bloclibrary.dev/architecture/) — feature-first layering, the bloc-to-bloc rule, repositories, presentation/domain/data direction.
- [Bloc concepts](https://bloclibrary.dev/bloc-concepts/) — `Bloc`, `Cubit`, transitions, observers, error handling.
- [Flutter Bloc concepts](https://bloclibrary.dev/flutter-bloc-concepts/) — `BlocProvider`, `BlocBuilder`, `BlocListener`, `BlocConsumer`, `RepositoryProvider`.
- [Modeling state](https://bloclibrary.dev/modeling-state/) — sealed-state guidance.
- [Naming conventions](https://bloclibrary.dev/naming-conventions/) — event / state / bloc class names.
- [Testing](https://bloclibrary.dev/testing/) — `bloc_test`, mocking, expected-state lists.
- [Migration guides](https://bloclibrary.dev/migration/) — between major versions.

### Tier 2 — felangel/bloc repository

- [felangel/bloc](https://github.com/felangel/bloc) — source.
- [Examples](https://github.com/felangel/bloc/tree/master/examples) — Felix Angelov's reference apps (login, weather, todos, firestore_todos, infinite_list, github_search). Official patterns.
- [Issues](https://github.com/felangel/bloc/issues) — closed issues often clarify the team's position.
- [Discussions](https://github.com/felangel/bloc/discussions) — Felix Angelov frequently weighs in.
- Package CHANGELOGs — [bloc](https://github.com/felangel/bloc/blob/master/packages/bloc/CHANGELOG.md), [flutter_bloc](https://github.com/felangel/bloc/blob/master/packages/flutter_bloc/CHANGELOG.md), [hydrated_bloc](https://github.com/felangel/bloc/blob/master/packages/hydrated_bloc/CHANGELOG.md), [bloc_test](https://github.com/felangel/bloc/blob/master/packages/bloc_test/CHANGELOG.md).

### Tier 3 — pub.dev pages for the locked stack

- [flutter_bloc](https://pub.dev/packages/flutter_bloc) · [bloc](https://pub.dev/packages/bloc) · [hydrated_bloc](https://pub.dev/packages/hydrated_bloc) · [bloc_concurrency](https://pub.dev/packages/bloc_concurrency) · [bloc_test](https://pub.dev/packages/bloc_test) · [equatable](https://pub.dev/packages/equatable) · [formz](https://pub.dev/packages/formz) · [replay_bloc](https://pub.dev/packages/replay_bloc) (situational).

### Tier 4 — Aligned tooling

- [Very Good Ventures blog](https://verygood.ventures/blog) — VGV is the company behind much of the ecosystem; posts reflect team preferences.
- [DCM Bloc lint rules](https://dcm.dev/docs/rules/bloc/) — Bloc-aligned lints. `avoid-passing-bloc-to-bloc` is the rule the cross-feature reactions decision in this skill mirrors.

Citations to these sources appear inline in `MEMORY.md` and several `references/*.md` files. When updating any of those, follow the citation convention: link to the specific page (not the root), and include a short quote so the reasoning survives even if the URL later moves.

## Default workflow for a new feature (TDD red-green-refactor)

Each step pairs **test first, code second**. Confirm `flutter test` after every "green" step.

1. Confirm the feature name and one-line purpose with the user.
2. Invoke `agents/feature-scaffolder.md` to generate the folder skeleton — failing tests + empty impl stubs.
3. Define the entity in `domain/entities/` (write equality + `props` test if non-trivial → make it pass).
4. Define the abstract repo in `domain/repositories/`.
5. **(red)** Write the bloc test — events in, expected state lists out — covering every handler you intend to write. Run `flutter test`; expect reds.
6. **(green)** Define the bloc events + states (sealed-state contract; formz exemption only when `FormzSubmissionStatus` applies). Implement handlers. Always set a `bloc_concurrency` transformer on user-input events. Run `flutter test`; expect greens.
7. **(refactor)** Tidy the bloc and state shape. Re-run tests.
8. **(red)** Write the repo impl test — every exception → failure mapping branch. Run `flutter test`; expect reds.
9. **(green)** Implement the repo in `data/repositories/`. Catch `AppException`, return `Result<T, AppFailure>`. Re-run tests.
10. **(red)** Write the data source test — request shape + exception throwing for each error mode. Run `flutter test`; expect reds.
11. **(green)** Implement the data source in `data/datasources/` (uses `Dio` / local provider; throws `AppException` only). Re-run tests.
12. Implement the model in `data/models/` with `@JsonSerializable`.
13. Wire the feature into `lib/app/injection.dart` (data source → repo → bloc).
14. Add the route to `lib/core/router/routes.dart` and `lib/core/router/app_router.dart`.
15. **(red)** Write a widget test for the page covering loaded / error / empty states.
16. **(green)** Build the page in `presentation/pages/` and any feature widgets. `BlocProvider` from `getIt`.
17. Run `agents/codegen-runner.md` to regenerate `*.g.dart` + `app_localizations.dart`.
18. Run `agents/bloc-verifier.md` to confirm no rule violations (including: every new source file has its test).
19. Run `agents/flutter-tester.md` (`dart format` + `flutter analyze` + `flutter test`).

## Default workflow for editing an existing feature (TDD)

1. Read the feature's existing `bloc/`, `repositories/`, and `entities/` first. Match the conventions in place.
2. **(red)** Add or modify the test that would fail under the desired new behavior. Run `flutter test`; confirm the relevant test fails for the *expected* reason (not "compilation error" — fix any compile errors first by adding stub APIs).
3. **(green)** Implement the change. If the change adds a field to a state class, update `props` in the same edit. If it touches a repo signature, also touch the abstract domain repo and the impl.
4. **(refactor)** Tidy. Re-run the full suite.
5. After edits, run `agents/codegen-runner.md` if any annotated file changed.
6. Run `agents/flutter-tester.md` before declaring done.

A bug fix follows the same shape: write a failing test that *demonstrates* the bug, then fix.

## Why this is opinionated

A skill that says "follow best practices" is useless because every team's best practices differ. This skill encodes a single set of choices on every contested decision (Bloc not Riverpod, Equatable not Freezed, `Result<T, F>` not `Either`, sealed classes not flag-based states, three-layer feature-first not layer-first). The point is consistency across the entire body of work over years, not "pick the best for this one project."

If a future decision genuinely needs to change, change it in `MEMORY.md` first with a dated entry explaining why, then update this file and the templates. Don't deviate silently in one project.
