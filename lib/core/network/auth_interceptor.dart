import 'package:cis_crm/core/network/auth_api.dart';
import 'package:cis_crm/core/network/token_storage.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor({
    required TokenStorage tokens,
    required AuthApi authApi,
  })  : _tokens = tokens,
        _authApi = authApi;

  final TokenStorage _tokens;
  final AuthApi _authApi;

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
    } catch (_) {
      await _tokens.clear();
      handler.next(err);
    }
  }
}
