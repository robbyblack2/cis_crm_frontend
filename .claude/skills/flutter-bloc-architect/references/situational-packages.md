# Situational Packages

Packages **not** pinned in the base `pubspec.yaml`. When a project needs one, add it to that project's pubspec, follow the canonical setup below, and do not modify the skill template.

## Image handling

### `cached_network_image`
Network images with disk + memory caching, placeholders, error widgets.
```yaml
cached_network_image: ^3.4.1
```
```dart
CachedNetworkImage(
  imageUrl: url,
  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
)
```
Wrap in `core/widgets/app_network_image.dart` so brand defaults stay centralized.

### `image_picker`, `flutter_image_compress`
Camera/gallery picking + client-side compression before upload.

## Connectivity / device

### `connectivity_plus`
```yaml
connectivity_plus: ^6.0.5
```
Canonical wiring is a `ConnectivityCubit` at `lib/core/connectivity/connectivity_cubit.dart` exposing `enum ConnectivityStatus { online, offline }`. Not `HydratedCubit` — connectivity is transient.

```dart
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit(Connectivity connectivity)
      : super(ConnectivityStatus.online) {
    _sub = connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      emit(isOnline ? ConnectivityStatus.online : ConnectivityStatus.offline);
    });
  }
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  @override Future<void> close() { _sub.cancel(); return super.close(); }
}

enum ConnectivityStatus { online, offline }
```

Banner shown via the App-root `MultiBlocListener` reacting to `ConnectivityStatus.offline` (calls `ErrorBanner.show(context, message: l.failure_network)`); dismissed via `ErrorBanner.hide(context)` when back online. **Repos do NOT branch on connectivity** — they make the call, fail with `NetworkFailure`, and the UI handles the failure. True offline-first (cache fallbacks, write queues) is a per-project decision.

### `package_info_plus`
```yaml
package_info_plus: ^8.0.2
```
Use in an `AppInfoCubit` that exposes `PackageInfo` for Settings/About pages.

### `permission_handler`
Runtime permission requests cross-platform. Wrap in `core/permissions/permissions_service.dart`.

## URL / sharing

### `url_launcher`
```yaml
url_launcher: ^6.3.0
```
Wrap in helpers — `core/extensions/url_extensions.dart`:
```dart
Future<bool> launchEmail(String to, {String? subject}) async {
  final uri = Uri(scheme: 'mailto', path: to, queryParameters: {
    if (subject != null) 'subject': subject,
  });
  return launchUrl(uri);
}
```

### `share_plus`
Standard share-intent. Use directly; no wrapper needed.

## Errors / observability

### `sentry_flutter` + `sentry_dio`

Opt-in per project via `FlavorConfig.sentryDsn`. When the DSN is non-null, `main.dart` wraps `runApp` in `SentryFlutter.init`; otherwise `runApp` is called directly. No `ErrorReporter` interface — observer + global error handlers each have an inline `if (Sentry.isEnabled) ...`.

```dart
if (config.sentryDsn != null) {
  await SentryFlutter.init(
    (o) {
      o.dsn = config.sentryDsn;
      o.environment = config.flavorName;
      o.tracesSampleRate = config.sentryTracesSampleRate;  // 0.1 prod / 1.0 dev
      o.beforeSend = scrubPii;                              // PII scrubber, mandatory
    },
    appRunner: () => runApp(const App()),
  );
} else {
  runApp(const App());
}
```

**PII scrubber is mandatory** at `lib/core/observability/sentry_scrub.dart`. Default impl strips emails, IP addresses, cookies, request bodies; keeps stable user IDs only. Projects extend, never replace with a no-op.

**`sentry_dio` interceptor** added automatically when Sentry is enabled — wraps every Dio call in a transaction for APM. No manual span instrumentation by default; trust auto-tracing.

**State-type-only breadcrumbs** in `AppBlocObserver.onChange`:
```dart
if (Sentry.isEnabled) {
  Sentry.addBreadcrumb(Breadcrumb(
    category: 'bloc',
    message: '${bloc.runtimeType}: ${change.nextState.runtimeType}',
    level: SentryLevel.info,
  ));
}
```
**Never log state contents.** Aligns with the no-state-contents-in-logs rule.

## Push / notifications

### `firebase_messaging`, `flutter_local_notifications`
The standard pair. Configure native projects (APNS for iOS, FCM for Android), then wire a `NotificationsRepository` in `core/notifications/`.

## Analytics

### `firebase_analytics` or `mixpanel_flutter`
Pick one per project. Wrap in `core/analytics/analytics_repository.dart` so swapping vendors is a one-file change.

## Local databases

### `drift`
Best Dart SQL ORM. Type-safe queries, declarative migrations. Add when you need relational queries beyond key-value.

### `isar` (v3) or `hive_ce`
NoSQL key-value/object stores. Faster than `drift` for simple lookup workloads. `hive_ce` is the maintained community fork of `hive` (the original is unmaintained).

## Auth providers

### `firebase_auth`, `google_sign_in`, `sign_in_with_apple`
Wrap each in a `*_data_source.dart` under `features/auth/data/datasources/`. The `AuthRepositoryImpl` orchestrates between them.

## Camera / location / maps

### `camera`, `geolocator`, `google_maps_flutter`, `mapbox_maps_flutter`
App-specific. When added, build a feature folder for them rather than scattering native plugin calls.

## Theming / animation

### `flex_color_scheme`
Generate full M3-themed `ThemeData` from a small config. Switch to this when hand-rolled theming exceeds 10 component overrides.

### `flutter_animate`, `lottie`
Declarative animations + Lottie. Use `flutter_animate` for one-line fade/scale/slide; reserve Lottie for designer-supplied animations.

## Audio / video

### `just_audio`, `video_player` + `chewie`
The standard players. Wrap in a feature module if used heavily.

## Date / time

### `timeago`
"3 minutes ago" formatting. Use directly.

## Forms (already in base via `formz`)

If `formz` doesn't fit and you need a more declarative builder, look at `reactive_forms`. Default is `formz` because it's BLoC-team-aligned and pairs cleanly with bloc's event-driven model.

## Logging upgrade

### `talker`, `talker_bloc_logger`, `talker_dio_logger`
If `logger` + a hand-rolled `BlocObserver` becomes burdensome, swap to the Talker stack — auto-logs every event, transition, and Dio call without writing a custom observer. Update `MEMORY.md` if making the swap.

## Native flavors (opt-in for the 5% case)

### `flutter_flavorizr`

The skill's default is **Path A** — Dart-side flavors via `--dart-define=FLAVOR=...`, no native gradle/iOS flavors. Bare `flutter run` works on every platform. Add `flutter_flavorizr` only when a project genuinely needs **dev and prod installable side-by-side on the same device** (different bundle IDs, different launcher icons).

```yaml
dev_dependencies:
  flutter_flavorizr: ^2.2.3
```

Cost: bare `flutter run` no longer works on Android (gradle product flavors require `--flavor`). The Makefile becomes the canonical run command (`make run` always passes `--flavor prod`). Document the deviation in the project's MEMORY before adding.

Known iOS issues to patch after `dart run flutter_flavorizr`:
- Re-link `LaunchScreen.storyboard` in each xcconfig — flavorizr drops the reference.
- Fix `Info.plist` `CFBundleDisplayName` to read `$(APP_DISPLAY_NAME)` from xcconfig.
- Register schemes in `xcschememanagement.plist` so they appear in Xcode/VS Code.
- Repair `Runner.xcscheme` xcconfig pointers per scheme.

## Feature flags / remote config

### `firebase_remote_config` (or `launchdarkly_flutter_client_sdk`, `statsig`, etc.)

The skill ships an abstract `FeatureFlagService` interface at `lib/core/flags/feature_flag_service.dart` with a no-op default impl. Every flag has a hardcoded default in `FeatureFlags` so the app must work even when remote config is unreachable.

When opting in:

```dart
class FirebaseFeatureFlagService implements FeatureFlagService {
  FirebaseFeatureFlagService(this._rc);
  final FirebaseRemoteConfig _rc;

  @override
  bool boolValue(String name, {required bool defaultValue}) {
    final v = _rc.getValue(name);
    return v.source == ValueSource.valueStatic ? defaultValue : v.asBool();
  }
  // ... other methods
}
```

Register in DI replacing the no-op:
```dart
getIt.registerLazySingleton<FeatureFlagService>(
  () => FirebaseFeatureFlagService(FirebaseRemoteConfig.instance),
);
```

In dev flavors, expose a debug screen at `/debug/flags` listing every known flag with toggle UI. Toggles persist to `SharedPreferences` and override remote values until cleared.

## Codegen quality-of-life

### `go_router_builder`
```yaml
dev_dependencies:
  go_router_builder: ^2.7.1
```
`@TypedGoRoute<HomeRoute>(path: '/')` generates compile-time-checked navigation. Add when the route table is large or typo-prone.

### `flutter_gen_runner`
```yaml
dev_dependencies:
  flutter_gen_runner: ^5.7.0
```
`Assets.images.logo.image()` instead of `Image.asset('assets/images/logo.png')`. Eliminates asset path typos.

### `mason_cli`
Felix Angelov's brick-based scaffolder. Pair with this skill to generate features from the CLI as well as via the agent.

## Env / secrets

### `envied`
Compile-time `.env` codegen. More secure than `flutter_dotenv` because secrets are embedded at build time, not parsed at runtime. Add when secrets enter the codebase.

## Testing

### `golden_toolkit` or `alchemist`
Visual regression testing with golden file snapshots.

### `patrol`
Integration testing that can drive native dialogs (permissions, biometrics). The default `integration_test` package is fine for simple flows; reach for `patrol` when tests need to interact with system UI.

### `network_image_mock`
Mocks `Image.network` in widget tests so they don't actually fetch.

## Adding a situational package — checklist

1. Add the package to that project's `pubspec.yaml`.
2. Run `flutter pub get`.
3. Write the wrapper(s) in `core/<area>/` so the rest of the app talks to YOUR API, not the package's.
4. Add the wrapper to `lib/app/injection.dart`.
5. Add a brief test for the wrapper (mocking the underlying package).
6. Document the addition in the project's README under "Dependencies" — this is so the next person reading the codebase knows why a non-base package is present.
