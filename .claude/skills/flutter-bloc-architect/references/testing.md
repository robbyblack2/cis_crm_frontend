# Testing

**TDD is mandatory in this skill. Every change is red → green → refactor.** Defer to the user's overall `tdd` skill for the procedural rules; this file documents the Flutter-specific particulars.

> Note on the BLoC team's official position: [bloclibrary.dev/testing](https://bloclibrary.dev/testing/) and the [`bloc_test` README](https://github.com/felangel/bloc/blob/master/packages/bloc_test/README.md) treat `blocTest` as a **tool**, not a workflow mandate. Mandatory TDD is **a project-stricter posture**, not a quote from the docs. The `bloc_test` API itself is fully aligned with what's below.

`test/` mirrors `lib/` exactly. Tools: `bloc_test`, `mocktail`, `flutter_test`.

## The TDD loop in this stack

### Red — failing test first

1. Write the test BEFORE the implementation exists. For a new bloc, create the empty class with a single `super(const XxxInitial())` so the test compiles, but no event handlers. For a new repo, declare the abstract method on `domain/repositories/Xxx.dart` and an empty `data/repositories/XxxImpl.dart` that returns `throw UnimplementedError()`.
2. Run `flutter test`. The new tests must fail with a **meaningful** message — assertion mismatch on expected state list, or `UnimplementedError`. NOT a compile error: fix compile errors first by adding stub APIs.
3. Commit the failing tests + stubs together if you're working in a feature branch — it's a recoverable checkpoint.

### Green — minimum code to pass

1. Implement only what the failing test demands. Do not add fields, branches, error handling, or refactors beyond what the test asserts.
2. Run `flutter test`. Expect the previously-red tests to turn green and no other tests to regress.
3. If a green is hard to reach, the test was written wrong (probably testing implementation, not behavior) — go back and fix the test, not the impl.

### Refactor — restructure with confidence

1. With the bar green, restructure: extract helpers, rename, deduplicate, simplify state shape, tighten types.
2. Run `flutter test` after **every** refactor step. A refactor that turns a green red is a bug.

### Working order for a feature

For a new feature, the TDD order matches the architecture-from-inside-out direction:

1. Entity equality test (if entity is non-trivial) → write entity → green.
2. Bloc test (every event-to-state path) → write states + bloc handlers → green.
3. Repo impl test (every exception → failure mapping branch) → write repo impl → green.
4. Data source test (request shape + exception throwing) → write data source → green.
5. Widget test (loaded / loading / empty / error states) → write page + view widgets → green.

Each layer's test mocks the layer below it. Bloc tests mock `Repository`. Repo impl tests mock `RemoteDataSource` / `LocalDataSource`. Data source tests mock `Dio`.

## Bloc tests

Use `blocTest` from `bloc_test`. Full parameter list:

- `build`: returns a fresh bloc/cubit with mocked deps.
- `setUp`: runs before `build`. Use for stubbing mocks that the bloc reads in its constructor.
- `seed`: sets the initial state directly (skip events to get there).
- `act`: dispatches the event(s) under test.
- `wait`: how long to wait between `act` and assertion. Required for `restartable()` debounce tests.
- `expect`: matcher or list of expected states emitted (matches the entire list).
- `errors`: matcher for exceptions thrown from inside the handler. Use when asserting an `addError` path.
- `verify`: post-assertion callback. Use to verify mock interactions.
- `tearDown`: runs after the test, after assertions. Mirrors `tearDown` in standard tests.
- `skip`: how many initial states to skip before applying `expect` (rarely needed).
- `tags`: standard `flutter_test` tags for filtering.

```dart
blocTest<FooBloc, FooState>(
  'emits [Loading, Loaded] on successful load',
  setUp: () {
    when(() => repo.getAll())
        .thenAnswer((_) async => Success(items));
  },
  build: () => FooBloc(repo),
  act: (bloc) => bloc.add(const FooLoadRequested()),
  expect: () => [const FooLoading(), FooLoaded(items)],
  verify: (_) => verify(() => repo.getAll()).called(1),
);
```

For optimistic flows, the expected state list captures the optimistic emit, the rollback, and the error:

```dart
expect: () => [
  FooLoaded([item1]),         // optimistic delete
  FooLoaded([item1, item2]),  // rollback
  FooError(failure),
],
```

## Repository impl tests

Mock the data source, instantiate the impl, assert the `Result<T, F>` shape:

```dart
test('converts NetworkException to NetworkFailure', () async {
  when(remote.getAll).thenThrow(const NetworkException());
  final result = await repository.getAll();
  expect(result, isA<Failure>());
  expect((result as Failure).error, isA<NetworkFailure>());
});
```

Test every branch of the exception-to-failure mapping.

## Widget tests

Wrap with `MaterialApp` + necessary providers. `bloc_test` ships `MockBloc<Event, State>` and `MockCubit<State>` base classes designed to integrate with `whenListen`:

```dart
class MockFooBloc extends MockBloc<FooEvent, FooState> implements FooBloc {}
class MockSettingsCubit extends MockCubit<SettingsState> implements SettingsCubit {}

testWidgets('shows loading then loaded list', (tester) async {
  final bloc = MockFooBloc();
  whenListen(
    bloc,
    Stream.fromIterable([const FooLoading(), FooLoaded(items)]),
    initialState: const FooInitial(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<FooBloc>.value(
        value: bloc,
        child: const FooView(),
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await tester.pumpAndSettle();
  expect(find.byType(ExampleTile), findsNWidgets(items.length));
});
```

`whenListen` from `bloc_test` is the canonical way to drive a mock bloc through a state sequence.

## HydratedBloc tests

`HydratedBloc.storage` is a static — set it once per test in `setUp`, otherwise constructing a `HydratedBloc` throws `StorageNotFound`:

```dart
import 'package:hydrated_bloc/hydrated_bloc.dart';

class _MockStorage extends Mock implements Storage {}

late Storage storage;

setUp(() {
  storage = _MockStorage();
  when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
  when(() => storage.read(any())).thenReturn(null);
  HydratedBloc.storage = storage;
});

tearDown(() async {
  await storage.clear();
});
```

Stub `storage.read` with the persisted JSON shape when testing the rehydration path.

## mocktail patterns

```dart
// Class
class MockAuthRepository extends Mock implements AuthRepository {}

// Stub
when(() => repo.login(any(), any())).thenAnswer(
  (_) async => Success(const User(id: '1', email: 'a@b.c')),
);

// Verify
verify(() => repo.login('a@b.c', any())).called(1);

// fallback values for custom types
class _FakeUser extends Fake implements User {}
setUpAll(() => registerFallbackValue(_FakeUser()));
```

`registerFallbackValue` is required when stubbing methods that take a non-primitive parameter through `any()`.

## bloc_test gotchas

- `expect: () => [...]` matches **the entire list** of states emitted. Add one extra state and the test fails. This is what makes blocTests strong.
- `seed` skips initial events — useful for testing handlers that assume a loaded state.
- `wait: const Duration(milliseconds: 100)` — needed for `restartable()` debounce tests so the timer can fire.
- For HydratedBloc tests, set `HydratedBloc.storage` to a mock in `setUp` (see `references/hydrated-bloc.md`).

## Test organization

- One test file per source file.
- One `group` per public API, one `test`/`blocTest` per scenario.
- Test names start with "emits [...]", "returns [...]", "calls [...]" — describe behavior, not implementation.

## Coverage targets

Aim for 100% coverage on the bloc layer (it's almost free with `blocTest`). 80%+ on repos. Widget tests cover happy path + key error paths. Don't chase coverage on `core/widgets/` glue — visual review is fine there.

A coverage drop without a corresponding deletion is a TDD violation in disguise — somewhere a code path was added without a test. Investigate before merging.

## Bug-fix TDD

A bug is "the code does X, the test should have caught it." The fix follows the same red-green-refactor:

1. **(red)** Write a test that *demonstrates the bug* — assert what the correct behavior would have been. Run `flutter test`; the test fails because the code is wrong.
2. **(green)** Fix the code. Run `flutter test`; the new test passes and nothing else regresses.
3. **(refactor)** Tidy.

Skipping the failing-test step on a bug fix means you have no protection against the bug coming back.

## Running tests

```sh
flutter analyze
flutter test
flutter test --coverage
```

Or invoke the `flutter-tester` agent (`agents/flutter-tester.md`) which runs both, parses output, and reports failures with file:line.
