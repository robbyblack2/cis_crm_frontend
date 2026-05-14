# Error Handling

Repositories return `Future<Result<T, AppFailure>>` and never throw. Data sources throw `AppException`. Repositories convert exceptions into typed failures. Blocs `switch` exhaustively on results.

> **Deliberate departure from the official BLoC examples.** [`flutter_weather`](https://github.com/felangel/bloc/tree/master/examples/flutter_weather) and [`flutter_login`](https://github.com/felangel/bloc/tree/master/examples/flutter_login) let typed exceptions propagate from the repo all the way to the bloc, and the bloc handler `try/catch`es them. This skill places the catch boundary inside the repository instead. Reasons: (1) makes the repo signature self-documenting (`Future<Result<T, AppFailure>>` says "this never throws"); (2) eliminates `try/catch` ceremony from every bloc handler; (3) makes "what failure modes can I see?" answerable by reading the failure-mapping switch in one file per repo. The BLoC team is silent on `Either`/`Result`-style types vs. propagating exceptions — neither pattern is officially endorsed nor discouraged. The skill picks the typed-result pattern; projects that prefer the team's example shape can deviate (record the deviation in their MEMORY).

## The chain

```
HTTP request → Dio → ErrorInterceptor → DioException(error: AppException)
              → DataSource (rethrows AppException, may also throw on parse)
              → Repository.method (catches AppException → returns Failure<T, AppFailure>)
              → Bloc handler (switch on Result)
              → State (XxxLoaded | XxxError(AppFailure))
              → UI (PageError / ErrorBanner / ErrorSnackbar reads `failure.localize(context)`)
```

`AuthInterceptor` runs on top of `ErrorInterceptor` and intercepts 401s before they reach the data source — refresh + retry, or signal logout via `AuthRepository`. Repos rarely see 401s.

## Repository pattern

```dart
class FooRepositoryImpl implements FooRepository {
  FooRepositoryImpl({required FooRemoteDataSource remote}) : _remote = remote;
  final FooRemoteDataSource _remote;

  @override
  Future<Result<List<Foo>, AppFailure>> getAll() async {
    try {
      final list = await _remote.getAll();
      return Success(list);
    } on AppException catch (e) {
      return Failure(_toFailure(e));
    } catch (e) {
      return Failure(UnknownFailure('Unexpected: $e'));
    }
  }

  AppFailure _toFailure(AppException e) => switch (e) {
    NetworkException(:final message) => NetworkFailure(message),
    UnauthorizedException(:final message) => UnauthorizedFailure(message),
    ValidationException(:final message, :final fieldErrors) =>
      ValidationFailure(message, fieldErrors: fieldErrors),
    ServerException(:final message, :final statusCode) =>
      ServerFailure(message, statusCode: statusCode),
    CacheException(:final message) => CacheFailure(message),
  };
}
```

Always include the `catch (e) { return Failure(UnknownFailure(...)); }` fallback so an unforeseen exception (e.g., `FormatException` from a malformed response) doesn't crash the bloc. The fallback is the safety net; the typed `on AppException` clause is the contract.

## Bloc handler pattern

```dart
Future<void> _onLoad(LoadRequested e, Emitter<FooState> emit) async {
  emit(const FooLoading());
  final result = await _repo.getAll();
  switch (result) {
    case Success(:final data):
      emit(FooLoaded(data));
    case Failure(:final error):
      emit(FooError(error));
  }
}
```

The bloc handler emits the failure as-is. The widget translates it via `failure.localize(context)` (the `FailureLocalizer` extension) when rendering. Special-case handling per failure type is rare — the canonical pattern is "emit the failure, let the UI decide how to render."

`UnauthorizedFailure` is NOT special-cased here. The Dio auth interceptor handles 401s automatically (refresh-token retry, then logout if refresh fails). When refresh fails, `AuthRepository.signOut()` pushes `AuthStatus.unauthenticated` to its broadcast stream, `AuthBloc` emits `AuthUnauthenticated`, the App-root `MultiBlocListener` clears user-scoped state, and the router's `redirect` bounces to `/login` via `refreshListenable`. The feature bloc's handler never imports or pokes `AuthBloc`.

## Failure → user-facing string

The `FailureLocalizer` extension in `lib/core/error/failure_localizer.dart` maps each `AppFailure` subtype to its localized message via `AppLocalizations`. Widgets call:

```dart
case FeatureError(:final failure):
  return PageError(
    title: 'Couldn\'t load',
    message: failure.localize(context),
    onRetry: () => context.read<FeatureBloc>().add(const RetryRequested()),
  );
```

Blocs never localize. They emit `AppFailure` instances; the widget layer translates.

## Server-side validation failures → individual fields

`ValidationFailure` carries an optional `Map<String, String>? fieldErrors` (alongside its top-level message). When the server returns `400` with `{"errors": {"email": "already taken"}}`, the data source maps that into `ValidationFailure(message, fieldErrors: {'email': 'already taken'})`.

The form bloc reads `fieldErrors` and rebuilds each affected `FormzInput` with `dirty(value, customError: '...')`:

```dart
final result = await _repo.signIn(email: state.email.value, password: state.password.value);
switch (result) {
  case Success():
    emit(state.copyWith(status: FormzSubmissionStatus.success));
  case Failure(:final error):
    emit(_applyServerErrors(state, error)
        .copyWith(status: FormzSubmissionStatus.failure));
}
```

`_applyServerErrors` is a private helper that switches on the failure type:

```dart
LoginState _applyServerErrors(LoginState s, AppFailure f) {
  if (f is! ValidationFailure || f.fieldErrors == null) return s;
  return s.copyWith(
    email: f.fieldErrors!.containsKey('email')
        ? EmailInput.dirty(s.email.value, customError: f.fieldErrors!['email'])
        : s.email,
    password: f.fieldErrors!.containsKey('password')
        ? PasswordInput.dirty(s.password.value, customError: f.fieldErrors!['password'])
        : s.password,
  );
}
```

For client-side field validation (before submit), use `formz`'s `FormzInput` validators. Reserve `ValidationFailure` for server-rejected input.

## Common pitfalls

- **Never throw from a repository.** Even for "impossible" cases — wrap in `UnknownFailure` instead.
- **Never let a `DioException` escape a data source.** Catch it, convert to `AppException`, throw that.
- **Never have an `on Exception catch (e)` in a bloc handler.** That's a sign the repo is throwing — fix the repo.
- **Don't silence failures in `RefreshRequested` handlers.** Emit the error state or fire a `BlocListener`-only side-effect-state for a snackbar.
