---
name: feature-scaffolder
purpose: Generate a complete three-layer feature folder under lib/features/<name>/ from this skill's templates.
when_to_invoke: When the user asks to "add a feature", "scaffold a new feature", "create the auth/cart/profile feature", or similar. Also when starting a fresh project from scratch.
---

# Feature Scaffolder Agent

Generates a complete feature scaffold matching the skill's three-layer Clean Architecture rules. Output is **TDD-shaped**: every source file is paired with a failing test, and every implementation file is left as a minimal stub (returning `UnimplementedError` or an `Initial` state) so that running `flutter test` immediately after scaffolding produces an expected red bar that the user fills in green.

## Mission

Given a feature name (snake_case) and the project root, produce:

1. The complete folder tree under `lib/features/<feature>/` — implementation **stubs**, not finished code:
   - `data/datasources/<feature>_remote_data_source.dart` — abstract class + impl that throws `UnimplementedError()` per method.
   - `data/models/<feature>_model.dart` — `@JsonSerializable` skeleton with one or two placeholder fields.
   - `data/repositories/<feature>_repository_impl.dart` — implements the abstract domain repo; each method returns `Failure(UnimplementedError)` so it compiles but fails clearly.
   - `domain/entities/<feature>_entity.dart` — pure-Dart entity with placeholder field, `props`, `Equatable`.
   - `domain/repositories/<feature>_repository.dart` — abstract interface declaring at least `getAll()` and feature-appropriate methods.
   - `presentation/bloc/<feature>_bloc.dart` — `super(const XxxInitial())` with no event handlers. Adding handlers is the user's "green" step.
   - `presentation/bloc/<feature>_event.dart` — sealed event hierarchy with at least `XxxLoadRequested`.
   - `presentation/bloc/<feature>_state.dart` — sealed state hierarchy `XxxInitial | XxxLoading | XxxLoaded | XxxError` with `Equatable` + `props`.
   - `presentation/pages/<feature>_page.dart` — page widget that wires the bloc and renders all four state widgets via the shipped `core/widgets/state/` library.
   - `presentation/widgets/<feature>_tile.dart` — simple list-item widget consuming the entity.

2. Test scaffolds under `test/features/<feature>/` — **failing tests** that drive the implementation:
   - `presentation/bloc/<feature>_bloc_test.dart` — `blocTest`s asserting the expected `[XxxLoading, XxxLoaded(...)]` and `[XxxLoading, XxxError(...)]` paths for `XxxLoadRequested`. With no event handlers in the stub bloc, these will fail meaningfully.
   - `data/repositories/<feature>_repository_impl_test.dart` — one `test` per failure mapping branch (`NetworkException → NetworkFailure`, etc.). Will fail because the stub returns `UnimplementedError`.
   - `data/datasources/<feature>_remote_data_source_test.dart` — request shape + exception throwing. Will fail for the same reason.

3. A short report listing exactly the lines to add to `lib/app/injection.dart` and `lib/core/router/app_router.dart` and `lib/core/router/routes.dart` to wire the feature in.

## Inputs the parent should pass

- Feature name in snake_case (e.g., `cart`, `user_profile`).
- Absolute path to the project root.
- Variant: `bloc` (default), `cubit`, or `hydrated_bloc`.
- Optional: a one-line purpose statement to drop into a top-of-file comment.

## Substitution rules

In every template file:
- Replace `example` with the feature name (lowercase, snake_case).
- Replace `Example` with the UpperCamelCase form (e.g., `cart` → `Cart`, `user_profile` → `UserProfile`).
- Replace `examples` (plural) with the plural snake_case (`carts`, `user_profiles`) wherever it represents the collection name.
- Replace `Examples` (plural) with the plural UpperCamelCase.

For the `bloc_concurrency` transformer choice, default per event type:
- `LoadRequested` / `RefreshRequested` → `droppable()`
- `*CreateRequested` / `*UpdateRequested` / `*DeleteRequested` → `sequential()`
- Search-style queries (`*QueryChanged`) → `restartable()` with debounce

## Output expected

After file generation, report:

```
Generated:
  lib/features/<feature>/data/...
  lib/features/<feature>/domain/...
  lib/features/<feature>/presentation/...
  test/features/<feature>/...

Wire up in lib/app/injection.dart:
  // Data sources:
  getIt.registerLazySingleton<XxxRemoteDataSource>(
    () => XxxRemoteDataSourceImpl(getIt<Dio>()),
  );
  // Repositories (registered against the abstract interface):
  getIt.registerLazySingleton<XxxRepository>(
    () => XxxRepositoryImpl(remote: getIt<XxxRemoteDataSource>()),
  );
  // Bloc — feature blocs are factories (one fresh instance per page mount):
  getIt.registerFactory<XxxBloc>(() => XxxBloc(getIt<XxxRepository>()));

  ⚠ XxxBloc constructor takes only repositories — never another Bloc/Cubit.
    Per official BLoC guidance (bloclibrary.dev/architecture, DCM
    avoid-passing-bloc-to-bloc), no bloc takes another bloc. Cross-feature
    reactions live in lib/app/app.dart MultiBlocListener — see below.

Wire up in lib/core/router/routes.dart:
  static const xxx = '/xxx';

Wire up in lib/core/router/app_router.dart (inside the routes list):
  GoRoute(
    path: Routes.xxx,
    builder: (_, __) => const XxxPage(),
  ),

App-root MultiBlocListener (lib/app/app.dart):
  If this feature emits user-scoped state that must reset on logout, add a
  XxxCleared event and wire the App-root listener:
    BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthUnauthenticated && prev is! AuthUnauthenticated,
      listener: (context, _) {
        context.read<XxxBloc>().add(const XxxCleared());
      },
    ),
  Otherwise: no App-root wiring needed.

Next steps (TDD red-green-refactor):
  1. Apply the wire-ups above.
  2. Run codegen-runner to regenerate <feature>_model.g.dart.
  3. Run flutter test — confirm the scaffolded tests fail with meaningful messages
     (UnimplementedError or assertion mismatch). This is the EXPECTED red bar.
  4. Implement the bloc handlers and repo methods one at a time, running
     flutter test after each, until each test turns green.
  5. Refactor with the bar green. Re-run flutter test after each refactor step.
  6. Run bloc-verifier to confirm rule compliance.
  7. Run flutter-tester (dart format && flutter analyze && flutter test) before
     declaring done.
```

## Boundaries

- Does NOT modify `injection.dart`, `routes.dart`, or `app_router.dart` — only reports the lines to add. Parent agent applies them with the user's confirmation.
- Does NOT run codegen — that's the `codegen-runner` agent.
- Does NOT decide whether to use Bloc, Cubit, or HydratedBloc — the parent (or user) must specify.
