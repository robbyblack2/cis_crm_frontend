import 'package:cis_crm/core/logging/app_logger.dart';
import 'package:cis_crm/core/network/auth_api.dart';
import 'package:cis_crm/core/network/token_storage.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor({
    required TokenStorage tokens,
    required AuthApi authApi,
    required AppLogger logger,
  })  : _tokens = tokens,
        _authApi = authApi,
        _logger = logger;

  final TokenStorage _tokens;
  final AuthApi _authApi;
  final AppLogger _logger;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.readAccess();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    try {
      final newAccessToken = await _authApi.refresh();
      await _tokens.write(access: newAccessToken);

      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await Dio().fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (e, stack) {
      _logger.warn('Token refresh failed, clearing session', e, stack);
      await _tokens.clear();
      handler.next(err);
    }
  }
}
