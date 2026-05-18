import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/contacts/data/models/company_model.dart';
import 'package:dio/dio.dart';

abstract class CompanyRemoteDataSource {
  Future<List<CompanyModel>> getCompanies();
  Future<CompanyModel> getCompany(String id);
  Future<CompanyModel> createCompany(CompanyModel company);
  Future<CompanyModel> updateCompany(CompanyModel company);
  Future<void> deleteCompany(String id);
}

class CompanyRemoteDataSourceImpl implements CompanyRemoteDataSource {
  CompanyRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<List<CompanyModel>> getCompanies() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/api/companies');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(CompanyModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<CompanyModel> getCompany(String id) async {
    try {
      final response =
          await dio.get<Map<String, dynamic>>('/api/companies/$id');
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return CompanyModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<CompanyModel> createCompany(CompanyModel company) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/companies',
        data: company.toJson(),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return CompanyModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<CompanyModel> updateCompany(CompanyModel company) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/companies/${company.id}',
        data: company.toJson(),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return CompanyModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deleteCompany(String id) async {
    try {
      await dio.delete<void>('/api/companies/$id');
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  AppException _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return const UnauthorizedException();
    }
    return ServerException(
      e.message ?? 'Server error',
      statusCode: statusCode,
    );
  }
}
