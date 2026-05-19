import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/contacts/data/models/company_model.dart';
import 'package:dio/dio.dart';

abstract class CompanyRemoteDataSource {
  Future<List<CompanyModel>> getCompanies();
  Future<CompanyModel> getCompany(String id);
  Future<CompanyModel> createCompany(CompanyModel company);
  Future<CompanyModel> updateCompany(CompanyModel company);
  Future<void> deleteCompany(String id);
  Future<List<Map<String, dynamic>>> getCompanyContacts(String id);
  Future<List<Map<String, dynamic>>> getCompanyRecords(String id);
  Future<List<Map<String, dynamic>>> getCompanySubscriptions(String id);
  Future<List<Map<String, dynamic>>> getCompanyTimeline(String id);
  Future<List<Map<String, dynamic>>> getCompanyNotes(String id);
  Future<List<Map<String, dynamic>>> getCompanyFiles(String id);
  Future<List<Map<String, dynamic>>> getCompanyProducts(String id);
  Future<List<Map<String, dynamic>>> getCompanyLineItems(String id);
  Future<void> bulkAssign(List<String> ids, String ownerId);
  Future<void> bulkTag(List<String> ids, List<String> tags);
  Future<void> bulkDelete(List<String> ids);
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

  @override
  Future<List<Map<String, dynamic>>> getCompanyContacts(String id) async {
    try {
      final response =
          await dio.get<Map<String, dynamic>>('/api/companies/$id/contacts');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCompanyRecords(String id) async {
    try {
      final response =
          await dio.get<Map<String, dynamic>>('/api/companies/$id/records');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCompanySubscriptions(
    String id,
  ) async {
    try {
      final response = await dio
          .get<Map<String, dynamic>>('/api/companies/$id/subscriptions');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> _getSubResource(
    String id,
    String resource,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/companies/$id/$resource',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCompanyTimeline(String id) =>
      _getSubResource(id, 'timeline');

  @override
  Future<List<Map<String, dynamic>>> getCompanyNotes(String id) =>
      _getSubResource(id, 'notes');

  @override
  Future<List<Map<String, dynamic>>> getCompanyFiles(String id) =>
      _getSubResource(id, 'files');

  @override
  Future<List<Map<String, dynamic>>> getCompanyProducts(String id) =>
      _getSubResource(id, 'products');

  @override
  Future<List<Map<String, dynamic>>> getCompanyLineItems(String id) =>
      _getSubResource(id, 'line-items');

  @override
  Future<void> bulkAssign(List<String> ids, String ownerId) async {
    try {
      await dio.post<void>(
        '/api/companies/bulk-assign',
        data: {'company_ids': ids, 'owner_id': ownerId},
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> bulkTag(List<String> ids, List<String> tags) async {
    try {
      await dio.post<void>(
        '/api/companies/bulk-tag',
        data: {'company_ids': ids, 'tags': tags},
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> bulkDelete(List<String> ids) async {
    try {
      await dio.post<void>(
        '/api/companies/bulk-delete',
        data: {'company_ids': ids},
      );
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
