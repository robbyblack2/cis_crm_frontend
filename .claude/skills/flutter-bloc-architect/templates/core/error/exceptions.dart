/// The sealed exception hierarchy thrown by data sources.
///
/// Data sources may throw any subtype of [AppException]. Repositories
/// catch them and convert to `Failure<T, AppFailure>`. Blocs never see
/// these — they only see [AppFailure] subtypes.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// Server returned a non-2xx response.
final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});

  final int? statusCode;
}

/// No internet, DNS failure, socket error, or DioException of network type.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

/// Local cache read/write failure.
final class CacheException extends AppException {
  const CacheException([super.message = 'Cache error.']);
}

/// 401 / 403 — caller is not authenticated or not authorized.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized.']);
}

/// 400 / 422 — server rejected the input.
///
/// [fieldErrors] maps field names to localized error messages (e.g.,
/// `{'email': 'already taken'}`). The repository converts this into
/// `ValidationFailure(message, fieldErrors: ...)` and the form bloc
/// rebuilds each affected `FormzInput` with `customError`.
final class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors});

  final Map<String, String>? fieldErrors;
}
