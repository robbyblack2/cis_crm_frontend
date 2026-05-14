import 'package:dio/dio.dart';

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
