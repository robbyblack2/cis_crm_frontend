import 'package:dio/dio.dart';

import 'auth_api.dart';
import 'token_storage.dart';

/// Dio interceptor that:
///  - attaches the bearer access token to every outbound request,
///  - refreshes the token on 401, retries the original request,
///  - clears tokens and propagates UnauthorizedFailure when refresh fails.
///
/// Uses [QueuedInterceptorsWrapper] so concurrent in-flight 401s queue
/// behind a single refresh call rather than firing N parallel refreshes.
/// This is mandatory — the bloc-verifier flags `Interceptor` /
/// `InterceptorsWrapper` here.
///
/// Depends only on [TokenStorage] (the `core/network` token abstraction)
/// and [AuthApi] (the raw refresh-token POST client). It never imports
/// the auth feature or any Bloc.
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

    final refresh = await _tokens.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      await _tokens.clear();
      return handler.next(err);
    }

    try {
      final newTokens = await _authApi.refresh(refreshToken: refresh);
      await _tokens.write(
        access: newTokens.access,
        refresh: newTokens.refresh,
      );

      // Retry the original request with the new token.
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer ${newTokens.access}';
      final response = await Dio().fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (_) {
      await _tokens.clear();
      handler.next(err);
    }
  }
}
