sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;
}

final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});

  final int? statusCode;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Cache error.']);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized.']);
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors});

  final Map<String, String>? fieldErrors;
}
