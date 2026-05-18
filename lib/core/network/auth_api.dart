import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio, {required String baseUrl}) : _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  Future<String> refresh() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/auth/refresh',
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty refresh response',
      );
    }
    final inner = data['data'] as Map<String, dynamic>;
    return inner['access_token'] as String;
  }
}
