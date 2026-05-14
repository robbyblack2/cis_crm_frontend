import 'package:cis_crm/core/env/flavor_config.dart';
import 'package:cis_crm/core/logging/app_logger.dart';
import 'package:cis_crm/core/network/auth_api.dart';
import 'package:cis_crm/core/network/auth_interceptor.dart';
import 'package:cis_crm/core/network/error_interceptor.dart';
import 'package:cis_crm/core/network/logging_interceptor.dart';
import 'package:cis_crm/core/network/token_storage.dart';
import 'package:dio/dio.dart';

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
    ),
  );

  dio.interceptors.addAll([
    LoggingInterceptor(logger: logger, isProd: config.isProd),
    AuthInterceptor(tokens: tokens, authApi: authApi),
    ErrorInterceptor(),
  ]);

  return dio;
}
