import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/auth/data/models/user_model.dart';
import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserModel> currentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty login response');
      }
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException();
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw const UnauthorizedException('Invalid credentials.');
      }
      throw ServerException(
        e.message ?? 'Login failed',
        statusCode: statusCode,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dio.post<void>('/api/auth/logout');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException();
      }
      throw ServerException(
        e.message ?? 'Logout failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> currentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/auth/me');
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty user response');
      }
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException();
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw const UnauthorizedException();
      }
      throw ServerException(
        e.message ?? 'Failed to fetch user',
        statusCode: statusCode,
      );
    }
  }
}
