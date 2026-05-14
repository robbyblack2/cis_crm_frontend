import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// The sealed failure hierarchy used at every repository boundary.
///
/// Repositories return `Result<T, AppFailure>`. Blocs exhaustively
/// match on subtypes to emit feature-appropriate error states.
@immutable
sealed class AppFailure extends Equatable {
  const AppFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType($message)';
}

/// No internet, DNS failure, socket error, or any transport-level failure.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// Server returned a non-2xx response.
final class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// 401 / 403 — caller is not authenticated or not authorized.
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Unauthorized.']);
}

/// Input failed business validation.
///
/// [fieldErrors] maps field names to localized error messages so a form bloc
/// can rebuild each affected `FormzInput` with `dirty(value, customError: ...)`.
/// The map is populated from server responses like
/// `{"errors": {"email": "already taken"}}` and from client-side validators
/// that need to report multiple field issues at once.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {this.fieldErrors});

  final Map<String, String>? fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Local cache (Hive, secure storage, shared prefs, etc.) read/write failure.
final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Cache error.']);
}

/// Anything that didn't fit the categories above. Always include a message.
final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
