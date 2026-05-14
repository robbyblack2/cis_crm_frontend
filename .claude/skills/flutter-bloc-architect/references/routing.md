# Routing

`go_router` only. Never call `Navigator.push` directly. Centralized config in `core/router/app_router.dart`. Route paths in `core/router/routes.dart`.

The router is a singleton in DI (`getIt<GoRouter>()`), built at startup. It exposes a top-level `redirect` callback for gating, a `refreshListenable` driven by `AuthRepository.status`, and a `StatefulShellRoute.indexedStack` driving the adaptive bottom-nav / rail / drawer shell.

## refreshListenable: subscribe to the repository, not the bloc

The router's `refreshListenable` consumes `AuthRepository.status` (a broadcast `Stream<AuthStatus>`), **not** `AuthBloc.stream`. Reason: on cold start the router needs to evaluate redirect against the persisted auth status before any bloc has emitted its first state. The repository owns the source of truth; the bloc reacts to it. Wire:

```dart
GoRouter(
  navigatorKey: appNavigatorKey,
  refreshListenable: GoRouterRefreshStream(authRepo.status),
  redirect: appRedirect,
  routes: [...],
);
```

`appNavigatorKey` is the `GlobalKey<NavigatorState>` declared in `lib/app/app.dart`. It lets the auth interceptor, push handler, and localization escape-hatch reach the navigator without a bloc.

## Redirect priority chain

Highest priority first. The chain runs on every navigation and on every emission from `refreshListenable`:

1. **Force-upgrade required** → `Routes.forceUpgrade`. Driven by `AppUpdateCubit` reading `min_app_version` from `FeatureFlagService`. Only when force-upgrade is opted in for the project.
2. **Onboarding not seen** → `Routes.onboarding`. Driven by `OnboardingCubit extends HydratedCubit<bool>` (a single `seenIntro` boolean).
3. **Auth gate** → `Routes.login` (unauthenticated visit to a protected route) or `Routes.home` (authenticated visit to `/login`).
4. **No redirect** otherwise.

```dart
FutureOr<String?> appRedirect(BuildContext context, GoRouterState state) {
  // 1. Force-upgrade
  final update = context.read<AppUpdateCubit>().state;
  if (update is UpdateRequired &&
      state.matchedLocation != Routes.forceUpgrade) {
    return Routes.forceUpgrade;
  }
  // 2. Onboarding
  final seenIntro = context.read<OnboardingCubit>().state;
  if (!seenIntro && state.matchedLocation != Routes.onboarding) {
    return Routes.onboarding;
  }
  // 3. Auth gate
  final auth = context.read<AuthBloc>().state;
  final atLogin = state.matchedLocation == Routes.login;
  if (auth is AuthUnauthenticated && !atLogin) return Routes.login;
  if (auth is AuthAuthenticated && atLogin) return Routes.home;
  return null;
}
```

## Route paths

All paths are constants in `lib/core/router/routes.dart`. Bloc-verifier flags any string literal matching `r'^/[a-z]'` outside that file, the router config, and tests.

```dart
abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const forceUpgrade = '/force_upgrade';
  static const search = '/search';
  static const profile = '/profile';
  static const settings = '/settings';
  static const debugFlags = '/debug/flags';

  static String product(String id) => '/product/$id';
}
```

`go_router_builder` (`@TypedGoRoute`) is intentionally NOT used — it's a second codegen pipeline. The constants give you compile-time-checked references at call sites; that's sufficient.

## Adaptive shell — `StatefulShellRoute` + `AdaptiveScaffold`

The shell route powers the bottom-nav / rail / drawer. Each branch keeps its own `Navigator` so per-tab state survives tab switches. The `AdaptiveScaffold` widget at `lib/core/widgets/adaptive_scaffold.dart` picks the surface by viewport width using the breakpoints in `lib/core/responsive/breakpoints.dart` (compact / medium / expanded).

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => AdaptiveScaffold(
    navigationShell: shell,
    destinations: const [
      AdaptiveDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      AdaptiveDestination(
        icon: Icon(Icons.person_outlined),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ],
  ),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: Routes.profile, builder: (_, __) => const ProfilePage()),
    ]),
  ],
)
```

Login, onboarding, and force-upgrade live OUTSIDE the shell — they're full-screen routes without the nav surface.

## Deep linking

`go_router` handles standard URL deep links once the platform manifests are configured (`Info.plist` `CFBundleURLTypes` for iOS, `AndroidManifest.xml` `<intent-filter>` for Android). For app-link / universal-link work, add `app_links` (situational).

When a push notification arrives with a route in its payload, the push handler calls `appNavigatorKey.currentContext!.go(route)`. Cold-start payload check runs in `main.dart` after `configureDependencies` and before `runApp`.

## Bloc-driven navigation

Use `BlocListener` for one-shot navigation in response to a state change. Never navigate from inside `BlocBuilder` (it may run multiple times, causing loops).

For auth specifically, prefer the global redirect — the bloc emits `AuthAuthenticated`, `refreshListenable` re-fires, the redirect bounces from `/login` to `/`. Only use a page-level `BlocListener` for navigation when the trigger is feature-specific (e.g., "checkout succeeded → navigate to receipt").

## Common pitfalls

- `Navigator.of(context).push(MaterialPageRoute(...))` anywhere is a violation.
- Stringly-typed paths at call sites (`context.go('/profile')`) — bloc-verifier flags these. Use `Routes.profile`.
- Stream-subscribing inside `redirect` — wrong hook. Hand the stream to `refreshListenable`.
- Subscribing the router to `AuthBloc.stream` instead of `AuthRepository.status` — breaks cold-start gating because the bloc hasn't emitted yet.
