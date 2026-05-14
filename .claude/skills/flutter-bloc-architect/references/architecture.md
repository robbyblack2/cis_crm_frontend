# Architecture

The full reasoning behind the three-layer feature-first layout. Load when starting a new feature, when refactoring an existing one, or when explaining the structure to a teammate.

## The three layers

### `presentation/`
Widgets, blocs, pages. Renders state, dispatches events. **Knows about Flutter.** Imports from `domain/` only.

### `domain/`
Pure Dart. **Knows nothing about Flutter, JSON, HTTP, or storage.** Contains entities and abstract repository interfaces. Imports from nothing but `core/error/`. The domain layer compiles and runs on the Dart server runtime — that's the test of whether you've kept it pure.

### `data/`
Data sources, models (DTOs), repository implementations. Knows about JSON, Dio, secure storage, etc. Implements the abstract repos defined in `domain/`. Imports from `domain/` to satisfy contracts.

## Dependency direction

```
presentation/ ──▶ domain/ ◀── data/
```

`presentation/` and `data/` both point INTO `domain/`. They do not point at each other. This is what makes the bloc unit-testable — the bloc only depends on the abstract `XxxRepository` from `domain/`, so a mock satisfies it.

If your IDE reports a presentation file importing from `data/`, that's a violation. Either the type belongs in `domain/`, or you're skipping the abstraction.

## Feature-first vs layer-first

**Feature-first** (this skill):
```
features/auth/{data, domain, presentation}/
features/cart/{data, domain, presentation}/
```

**Layer-first** (NOT this skill):
```
blocs/{auth, cart}_bloc.dart
repositories/{auth, cart}_repository.dart
models/{user, product}.dart
screens/{login, cart}_screen.dart
```

Feature-first wins for any app that grows past ~8 screens because:
- Two devs can build `auth/` and `cart/` in parallel without merge conflicts.
- Deleting a feature is `rm -rf features/that_one`.
- Adding a feature touches the feature folder + injection.dart + app_router.dart and nothing else.
- Reading the file tree tells you what the app does.

## Cross-feature interaction

The rule: **no feature imports another feature directly,** and **no bloc takes another bloc as a constructor parameter.** This is the official BLoC team position — quoting [bloclibrary.dev/architecture/](https://bloclibrary.dev/architecture/):

> "While blocs expose streams, it may be tempting to make a bloc which listens to another bloc. You should not do this. This creates a dependency between two blocs... no bloc should know about any other bloc."

The DCM lint rule [`avoid-passing-bloc-to-bloc`](https://dcm.dev/docs/rules/bloc/avoid-passing-bloc-to-bloc/) flags exactly this. The bloc-verifier agent enforces it too.

Two allowed channels — pick by where the trigger originates.

### 1. (Default) Bridge via `BlocListener` at the App root — "push to presentation"

When the trigger IS a state change in another bloc — e.g., "auth went from authenticated to unauthenticated, clear the cart" — the bridge lives in the presentation layer at the App widget root. One file owns every cross-feature reaction in the app.

> **Project-stricter than docs.** bloclibrary.dev allows the bridge to live anywhere in the presentation layer (any `BlocListener` widget will do). This skill mandates the App-widget root specifically, so cross-feature reactions live in one auditable file rather than scattered through pages. Deliberate centralization, not an official requirement.

```dart
// lib/app/app.dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthBloc>()),
        BlocProvider.value(value: getIt<CartBloc>()),
        BlocProvider.value(value: getIt<RecentSearchesBloc>()),
      ],
      child: MultiBlocListener(
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
        child: MaterialApp.router(routerConfig: getIt<GoRouter>()),
      ),
    );
  }
}
```

`CartBloc` does not import `AuthBloc`. It just receives a `CartCleared` event like any other event. Adding a fourth user-scoped bloc means adding one line to the App-root listener.

### 2. (When non-bloc code is the source) Reactive repository — "push to domain"

When the trigger does NOT originate in a bloc — for example, the Dio auth interceptor catches a refresh-token failure and needs to flip the session to "signed out" — the repository owns a broadcast `Stream` and the feature's own bloc subscribes to its own repository. **Other features still use channel 1** (the App-root listener watches the auth feature's bloc).

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Stream<AuthStatus> get status;
  Future<Result<User, AppFailure>> signIn({...});
  Future<Result<void, AppFailure>> signOut();
}

// lib/features/auth/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokens);
  final _controller = StreamController<AuthStatus>.broadcast();

  @override
  Stream<AuthStatus> get status async* {
    yield await _readInitialStatus();
    yield* _controller.stream;
  }

  @override
  Future<Result<void, AppFailure>> signOut() async {
    await _tokens.clear();
    _controller.add(AuthStatus.unauthenticated);
    return const Success(null);
  }
}

// lib/features/auth/presentation/bloc/auth_bloc.dart
class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthInitial()) {
    _sub = _repo.status.listen((s) => add(_AuthStatusChanged(s)));
    on<_AuthStatusChanged>(_onStatusChanged);
  }
}
```

A bloc subscribing to **its own feature's repository** is normal — it's not bloc-to-bloc. The interceptor never sees a bloc; it calls `authRepository.signOut()`. The repository is the single source of truth, and the broadcast stream lets the bloc react.

**Other user-scoped features (cart, recent searches, drafts) do NOT subscribe to `AuthRepository`.** They react via the App-root `BlocListener` watching `AuthBloc`'s state. Otherwise every feature ends up coupled to the auth domain.

### 3. Shared types in `core/`

If two features need the same value type (e.g., a `Money` class, a `LocaleId`), it lives in `core/types/` or `core/value_objects/`. Both features import it from `core/`.

### What to never do

- ✗ A bloc taking another bloc in its constructor (`CartBloc(this._authBloc)`).
- ✗ A bloc subscribing to another feature's bloc (`_authBloc.stream.listen(...)`).
- ✗ A bloc subscribing to ANY repository it does not own (only `AuthBloc` subscribes to `AuthRepository`; `CartBloc` subscribing to `_authRepo.status` is a violation — that reaction belongs in the App-root `BlocListener`). **Project-stricter than docs.** bloclibrary.dev's "Connecting Blocs through Domain" example permits multiple blocs subscribing to one shared reactive repository (e.g., two blocs both reading `AppIdeasRepository.productIdeas()`). This skill routes those reactions through the App-root listener instead, to keep cross-feature coupling in one file.
- ✗ One bloc calling `add(...)` on another bloc.

The bloc-verifier agent flags all four.

## Multi-repo blocs (no usecases)

When a bloc needs to combine two or three repositories — checkout calling cart + payment + order, register calling auth + profile, etc. — inject all of them directly into the bloc constructor and orchestrate in the handler:

```dart
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc({
    required CartRepository cart,
    required PaymentRepository payment,
    required InventoryRepository inventory,
  })  : _cart = cart,
        _payment = payment,
        _inventory = inventory,
        super(const CheckoutInitial()) {
    on<CheckoutSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CartRepository _cart;
  final PaymentRepository _payment;
  final InventoryRepository _inventory;

  Future<void> _onSubmitted(
    CheckoutSubmitted event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutLoading());

    final cartResult = await _cart.current();
    if (cartResult case Failure(:final error)) {
      emit(CheckoutError(error));
      return;
    }
    final cart = (cartResult as Success).data;

    final stock = await _inventory.verify(cart.items);
    if (stock case Failure(:final error)) {
      emit(CheckoutError(error));
      return;
    }

    final charge = await _payment.charge(cart.total, event.method);
    if (charge case Failure(:final error)) {
      emit(CheckoutError(error));
      return;
    }

    final order = await _cart.checkout((charge as Success).data);
    switch (order) {
      case Success(:final data):
        emit(CheckoutSuccess(data));
      case Failure(:final error):
        emit(CheckoutError(error));
    }
  }
}
```

Two reasons this is preferred over a usecase layer:

1. **The bloc IS the orchestrator.** Its job is "events in → states out via business actions." Combining repos to satisfy an event is core bloc work, not a separate concern.
2. **No silent indirection.** A reader of the bloc can see exactly which repos and which operations participate in checkout. There's no need to navigate to a `usecases/` folder to find out what `Checkout` actually does.

Use cases (the Reso Coder Clean Architecture pattern) are NOT used in this stack. The cost (extra files, indirection, scaffold ceremony) outweighs the benefit (discoverability) for typical app scale. If a future project legitimately needs them — large team, same action invoked from many blocs — append a new MEMORY.md entry and reintroduce them.

## Repository → data source rule

A repository's constructor parameters are exclusively feature-scoped data sources, never `core/`-level providers:

```dart
// ✗ WRONG — repo skipping the data source layer
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio, this._storage);
  final Dio _dio;
  final SecureStorage _storage;
}

// ✓ CORRECT — repo depends on feature-scoped data sources
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.local});
  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;
}
```

The data source knows about feature-specific concerns (token storage keys, API endpoints, JSON shapes). The repository knows about business rules and failure mapping. The `core/` provider knows about raw I/O. Three jobs, three layers.

## When to skip a layer

For a one-screen utility feature that just renders a hardcoded list, the full three-layer split is overkill. It's still better to have the structure for consistency, but the `data/` layer can be a single in-memory repository, and the entity can double as the model. Don't shrink the structure — fill in the parts that exist with thinner content.

## When to add a `core/` subfolder

Add a new `core/<name>/` only when:
1. At least two features will use it.
2. It doesn't fit any existing core subfolder.
3. It isn't an external package's responsibility.

Otherwise it lives inside the feature that uses it.
