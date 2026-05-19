import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/settings/data/models/google_connection_model.dart';
import 'package:dio/dio.dart';

abstract interface class GoogleRemoteDataSource {
  Future<String> getAuthUrl();
  Future<GoogleConnectionModel> getStatus();
  Future<void> disconnect();
}

class GoogleRemoteDataSourceImpl implements GoogleRemoteDataSource {
  const GoogleRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<String> getAuthUrl() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/google/auth-url');
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Empty response');
      return data['url'] as String;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<GoogleConnectionModel> getStatus() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/google/status');
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Empty response');
      return GoogleConnectionModel.fromJson(data);
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _dio.post<Map<String, dynamic>>('/api/google/disconnect');
    } on DioException {
      rethrow;
    }
  }
}
