# DI Patterns

`get_it` for the dependency graph; `BlocProvider` for delivering blocs into the widget tree. Distinct jobs, both required.

> **Divergence from the official `flutter_bloc` example pattern.** [bloclibrary.dev/architecture](https://bloclibrary.dev/architecture/) and the [`RepositoryProvider`](https://pub.dev/documentation/flutter_bloc/latest/flutter_bloc/RepositoryProvider-class.html) class docs present `RepositoryProvider` / `MultiRepositoryProvider` as the canonical injectable pattern for non-bloc deps (repositories, data sources). This skill uses `get_it` instead. Both are production-safe; `get_it` scales better for deep dependency graphs and lets non-widget code (interceptors, services) resolve deps without a `BuildContext`. The trade-off: `RepositoryProvider`'s widget-tree scoping is lost, and projects using only `RepositoryProvider` won't be a drop-in fit. This is a deliberate, conscious choice — not a misreading of the official docs.

## Registration order

`lib/app/injection.dart` registers in five layers, bottom-up:

1. **Leaves** (no deps): `SecureStorage`, `SharedPreferences`.
2. **Data providers**: `Dio`, local DB clients, package_info, etc.
3. **Data sources**: concrete impls.
4. **Repositories**: registered against the abstract interface, instantiated with the concrete impl.
5. **Blocs**: app-wide as singletons, feature-scoped as factories.

## Singletons vs factories vs lazy singletons

| Method | When | Lifecycle |
|---|---|---|
| `registerSingleton<T>(instance)` | Already-constructed value (e.g., `SharedPreferences` after async init) | Lives for app lifetime |
| `registerLazySingleton<T>(() => …)` | Construction is cheap or only needed if used | First `getIt<T>()` triggers construction; lives for app lifetime |
| `registerFactory<T>(() => …)` | New instance per resolution | Discarded by the consumer |

**Blocs:**
- App-wide blocs (auth, theme, settings) → `registerLazySingleton`. One instance for the whole app session.
- Feature blocs (cart, search, profile-edit) → `registerFactory`. Each page mount gets a fresh bloc; closed when the page pops.

## Why feature blocs are factories

A feature bloc holds state that's tied to that screen's session. If the user navigates away and back, you usually want a clean bloc, not one that still holds the previous session's state. Factories give you that automatically.

The exception: if a feature has app-wide state that shouldn't reset on navigation (e.g., a shopping cart persisting across pages), make it a singleton.

## Wiring blocs into the widget tree

For singletons, use `BlocProvider.value` — the value already exists in `getIt`, the widget tree just needs to expose it. **Don't dispose** at unmount (it's still alive in `getIt`).

```dart
BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>())
```

For factories, use `BlocProvider(create: …)` — a fresh instance is created when the widget mounts and disposed when it unmounts.

```dart
BlocProvider<CartBloc>(
  create: (_) => getIt<CartBloc>()..add(const CartLoadRequested()),
)
```

Trailing `..add(...)` is the canonical way to dispatch the initial event. Don't put it in the bloc's constructor — that breaks `bloc_test`.

## MultiBlocProvider at app root

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
    BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
    BlocProvider<SettingsBloc>.value(value: getIt<SettingsBloc>()),
  ],
  child: MaterialApp.router(...),
)
```

Only **app-wide** blocs go here. Feature blocs go on their feature page, not at app root — they shouldn't be alive when the user isn't on that screen.

## Cross-bloc dependencies — disallowed

**No bloc takes another bloc in its constructor.** This is a hard rule per official BLoC team guidance ([bloclibrary.dev/architecture](https://bloclibrary.dev/architecture/) and the DCM lint `avoid-passing-bloc-to-bloc`):

> "While blocs expose streams, it may be tempting to make a bloc which listens to another bloc. You should not do this... no bloc should know about any other bloc."

```dart
// ✗ WRONG
getIt.registerFactory<CartBloc>(
  () => CartBloc(getIt<CartRepository>(), getIt<AuthBloc>()),
);
```

The bloc-verifier agent flags this and four related anti-patterns: bloc-typed constructor parameters, `<otherBloc>.stream.listen`, `<otherBloc>.add(...)` from inside another bloc, and a bloc subscribing to a sibling feature's repository.

## Resetting state on logout — App-root `MultiBlocListener`

When the user logs out, every user-scoped feature bloc should reset. The bridge lives in `lib/app/app.dart`, **not** inside any feature bloc.

```dart
// lib/app/app.dart
MultiBlocListener(
  listeners: [
    BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthUnauthenticated && prev is! AuthUnauthenticated,
      listener: (context, _) {
        context.read<CartBloc>().add(const CartCleared());
        context.read<RecentSearchesBloc>().add(const RecentSearchesCleared());
      },
    ),
  ],
  child: MaterialApp.router(...),
)
```

Adding a fourth user-scoped bloc means adding one line to that listener — `CartBloc` itself never imports `AuthBloc`, never sees `AuthState`. It receives `CartCleared` like any other event.

## When the trigger is non-bloc code — reactive repository

When the source is something other than a bloc state change — e.g., the Dio auth interceptor catching a refresh-token failure — the relevant repository owns a broadcast `Stream` and that feature's own bloc subscribes to its own repository. **Other features still react via the App-root listener.**

```dart
abstract class AuthRepository {
  Stream<AuthStatus> get status;
  Future<Result<void, AppFailure>> signOut();
}

// AuthBloc subscribes to its OWN feature's repository — fine.
class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthInitial()) {
    _sub = _repo.status.listen((s) => add(_AuthStatusChanged(s)));
  }
}
```

`CartBloc` does NOT subscribe to `AuthRepository.status`. That cross-feature reaction lives in the App-root listener watching `AuthBloc`'s state.

## Testing

For unit tests, register mocks in `setUp`:

```dart
setUp(() {
  GetIt.I.reset();
  GetIt.I.registerSingleton<AuthRepository>(MockAuthRepository());
});
```

Or, equivalently, construct the bloc directly with a mock repo and skip `get_it` entirely. Either is fine for unit tests; `get_it.reset()` is needed only for integration tests that exercise multiple features.
