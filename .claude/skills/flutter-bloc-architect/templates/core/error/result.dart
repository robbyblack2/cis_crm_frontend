/// Generic result type for handling success/failure with typed errors.
///
/// Repositories return `Future<Result<T, AppFailure>>` and never throw.
/// Bloc handlers exhaustively `switch` on the result.
///
/// Example:
/// ```dart
/// final result = await _repo.login(email, password);
/// switch (result) {
///   case Success(:final data):
///     emit(AuthAuthenticated(data));
///   case Failure(error: final NetworkFailure _):
///     emit(const AuthError('Check your connection.'));
///   case Failure(error: final UnauthorizedFailure _):
///     emit(const AuthError('Invalid credentials.'));
///   case Failure(:final error):
///     emit(AuthError(error.message));
/// }
/// ```
sealed class Result<T, F> {
  const Result();

  /// Convenience: returns the success value or `null`.
  T? get dataOrNull => switch (this) {
        Success<T, F>(:final data) => data,
        Failure<T, F>() => null,
      };

  /// Convenience: returns the failure or `null`.
  F? get failureOrNull => switch (this) {
        Success<T, F>() => null,
        Failure<T, F>(:final error) => error,
      };

  /// `true` if this is a [Success].
  bool get isSuccess => this is Success<T, F>;

  /// `true` if this is a [Failure].
  bool get isFailure => this is Failure<T, F>;
}

/// A successful result carrying [data].
final class Success<T, F> extends Result<T, F> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, F> && other.data == data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success<$T, $F>($data)';
}

/// A failed result carrying [error].
final class Failure<T, F> extends Result<T, F> {
  const Failure(this.error);

  final F error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, F> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure<$T, $F>($error)';
}
