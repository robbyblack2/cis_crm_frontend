# HydratedBloc

State that survives app restart. Auth, theme, settings, cart, onboarding flag — anything you'd expect to still be there after the user kills and re-opens the app.

## Setup (one-time, in main.dart)

The template `main.dart` already does this. The `kIsWeb` branch is mandatory — `path_provider` does not work in browsers, so web must use `HydratedStorageDirectory.web`:

```dart
WidgetsFlutterBinding.ensureInitialized();
HydratedBloc.storage = await HydratedStorage.build(
  storageDirectory: kIsWeb
      ? HydratedStorageDirectory.web
      : HydratedStorageDirectory(
          (await getApplicationDocumentsDirectory()).path,
        ),
);
```

Must run before any `HydratedBloc` is constructed. `path_provider` is in the base stack for this.

**Why `getApplicationDocumentsDirectory()` and not `getTemporaryDirectory()`** — the official `hydrated_bloc` README example uses temp; this skill uses documents because iOS/Android can evict temp directories under storage pressure. Hydrated state is durable, not cacheable.

## Per-bloc

Extend `HydratedBloc<Event, State>` instead of `Bloc<Event, State>`. Implement `fromJson` and `toJson`:

```dart
class CartBloc extends HydratedBloc<CartEvent, CartState> {
  CartBloc(this._repo) : super(const CartInitial()) {
    on<CartItemAdded>(_onAdd, transformer: sequential());
  }

  // ... handlers ...

  @override
  CartState? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'initial' => const CartInitial(),
      'loaded' => CartLoaded(
          (json['items'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(CartItemModel.fromJson)
              .toList(),
        ),
      _ => null,
    };
  }

  @override
  Map<String, dynamic>? toJson(CartState state) => switch (state) {
    CartInitial() => {'type': 'initial'},
    CartLoaded(:final items) => {
        'type': 'loaded',
        'items': items.map((i) => (i as CartItemModel).toJson()).toList(),
      },
    CartLoading() => null,   // skip transient states
    CartError() => null,     // skip error states; reload on next launch
  };
}
```

The `type` discriminator pattern is required because the state is a sealed union and `json_serializable` doesn't auto-dispatch unions. Every variant gets a string id; `fromJson` switches on it.

## What to persist, what to skip

**Persist:** `Initial`, `Loaded`, anything stable.

**Skip (return `null` from `toJson`):**
- Loading states — they restart on next launch anyway.
- Error states — surfacing yesterday's error on app open is bad UX.
- Any state holding a stream subscription or non-serializable resource.

Returning `null` from `toJson` is silent — HydratedBloc just doesn't write to disk.

## Models must have JSON

`fromJson`/`toJson` on the state delegate to the underlying entity types. For HydratedBloc to work, the persisted entities must extend the `data/` model (which has `@JsonSerializable`), not the bare `domain/` entity. A common pattern: store `List<XxxModel>` in the state when you need persistence.

## When `fromJson` throws

`HydratedBloc` catches exceptions from `fromJson` and falls back to the bloc's `super(initialState)` instead of crashing the app. The error is forwarded to `Bloc.observer.onError`. This means:

- A corrupted JSON file → app starts in initial state instead of crashing. Acceptable.
- A `fromJson` that *changed shape* in a release → users on that version see initial state until they re-do whatever they had persisted. Acceptable for theme/locale; problematic for auth or cart. Use the migration patterns below.

## Migrations

When you add a field to a persisted state, the old persisted JSON won't have it. Three options:

1. **Make the new field nullable** and tolerate old JSON.
2. **Bump a version field** in your JSON: include `'version': 2` in `toJson`, branch in `fromJson` to migrate v1 → v2 in code.
3. **Wipe storage on app upgrade** if persistence is non-critical (theme, last-tab) — call `HydratedBloc.storage.clear()` once in a startup migration.

For auth tokens specifically, prefer `flutter_secure_storage` over HydratedBloc — keys protected by Keychain/Keystore are more appropriate than HydratedBloc's plaintext JSON file. (The `AuthBloc` itself is `HydratedBloc` because the *bloc state* — `AuthAuthenticated(User)` — is not the secret; the access/refresh tokens stay in `TokenStorage`.)

### Logout — clear the storage

On logout, after `TokenStorage.clear()`, also clear any HydratedBloc state that's user-scoped:

```dart
await HydratedBloc.storage.clear();   // wipes ALL persisted blocs
// or, per-bloc:
cartBloc.clear();                      // wipes that bloc only
```

Whether to clear all or per-bloc depends on whether the project has app-wide hydrated state (theme, locale) that should survive across users on the same device.

## Race with stream subscriptions

When a `HydratedBloc` subscribes to a stream in its constructor (e.g., `AuthBloc` → `AuthRepository.status`), wire the listener **after** `super(...)` so it doesn't race with the rehydration:

```dart
class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthInitial()) {
    // super(...) triggers HydratedBloc.fromJson → may emit AuthAuthenticated.
    // The listener wires AFTER, so the first stream emission won't stomp
    // a successfully-rehydrated state.
    _sub = _repo.status.listen((s) => add(_AuthStatusChanged(s)));
    on<_AuthStatusChanged>(_onStatusChanged);
  }
}
```

This pattern is supported but undocumented in the package; the rule "subscribe after super" is project-specific and exists to prevent rehydration races.

## Testing

`HydratedBloc.storage` must be set in `setUp` for tests:

```dart
class _MockStorage extends Mock implements Storage {}

setUp(() {
  HydratedBloc.storage = _MockStorage();
  when(() => HydratedBloc.storage.read(any())).thenReturn(null);
});
```

Or use `HydratedStorage.webStorageDirectory` / a real temp dir for integration tests.
