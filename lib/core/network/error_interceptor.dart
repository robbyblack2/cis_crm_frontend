import 'package:cis_crm/core/error/exceptions.dart';
import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapToAppException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        type: err.type,
      ),
    );
  }

  AppException _mapToAppException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badCertificate:
        return const NetworkException('Certificate error.');

      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled.');

      case DioExceptionType.unknown:
        return NetworkException(err.message ?? 'Network error.');

      case DioExceptionType.badResponse:
        final code = err.response?.statusCode;
        final body = err.response?.data;
        final message = _extractMessage(body) ?? err.message ?? 'Server error.';
        if (code == 401 || code == 403) {
          return UnauthorizedException(message);
        }
        return ServerException(message, statusCode: code);
    }
  }

  String? _extractMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final m = body['message'] ?? body['error'] ?? body['detail'];
      if (m is String) return m;
    }
    if (body is String && body.isNotEmpty) return body;
    return null;
  }
}
