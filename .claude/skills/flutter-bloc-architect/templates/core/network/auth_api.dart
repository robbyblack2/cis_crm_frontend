import 'package:dio/dio.dart';

/// Raw HTTP client for the **refresh-token** endpoint only.
///
/// This client is intentionally separate from the auth feature's
/// `AuthRemoteDataSource`. The refresh call must be reachable from the
/// auth interceptor without crossing into `features/`. Login, logout,
/// /me, and password resets live on `AuthRemoteDataSource` — they are
/// only invoked from `AuthRepositoryImpl`, never from the interceptor.
///
/// Uses its own [Dio] instance (passed in) without the auth interceptor
/// attached, so refresh calls never themselves hit the 401 → refresh
/// loop.
class AuthApi {
  AuthApi(this._dio, {required String baseUrl}) : _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  Future<RefreshedTokens> refresh({required String refreshToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty refresh response',
      );
    }
    return RefreshedTokens(
      access: data['access_token'] as String,
      refresh: data['refresh_token'] as String,
    );
  }
}

class RefreshedTokens {
  const RefreshedTokens({required this.access, required this.refresh});
  final String access;
  final String refresh;
}
