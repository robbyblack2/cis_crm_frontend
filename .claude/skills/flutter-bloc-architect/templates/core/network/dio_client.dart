import 'package:dio/dio.dart';

import '../env/flavor_config.dart';
import '../logging/app_logger.dart';
import 'auth_api.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'logging_interceptor.dart';
import 'token_storage.dart';

/// Builds the application-wide [Dio] instance.
///
/// Registered as a singleton in `lib/app/injection.dart`. Feature data
/// sources receive this `Dio` — never construct ad-hoc Dio instances
/// elsewhere.
///
/// Interceptor order matters:
///   1. [LoggingInterceptor] — first in, last out, sees both the raw
///      outgoing request and the final response.
///   2. [AuthInterceptor] (`QueuedInterceptorsWrapper`) — attaches bearer,
///      refreshes on 401, queues concurrent 401s behind a single refresh.
///   3. [ErrorInterceptor] — maps DioException into AppException right
///      before the data source sees it.
Dio createDioClient({
  required FlavorConfig config,
  required AppLogger logger,
  required TokenStorage tokens,
  required AuthApi authApi,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.addAll([
    LoggingInterceptor(logger: logger, isProd: config.isProd),
    AuthInterceptor(tokens: tokens, authApi: authApi),
    ErrorInterceptor(),
  ]);

  return dio;
}
