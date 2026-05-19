import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:cis_crm/features/contacts/data/models/contact_model.dart';
import 'package:dio/dio.dart';

abstract class ContactRemoteDataSource {
  Future<PaginatedResponse<ContactModel>> getContacts({
    int page = 1,
    int perPage = 25,
  });
  Future<ContactModel> getContact(String id);
  Future<ContactModel> createContact(ContactModel contact);
  Future<ContactModel> updateContact(ContactModel contact);
  Future<void> deleteContact(String id);
}

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  ContactRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<PaginatedResponse<ContactModel>> getContacts({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/contacts',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response body');
      }
      final data = (body['data'] as List<dynamic>?) ?? [];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      final items =
          data.cast<Map<String, dynamic>>().map(ContactModel.fromJson).toList();
      return PaginatedResponse<ContactModel>(
        items: items,
        page: meta['page'] as int? ?? page,
        perPage: meta['per_page'] as int? ?? perPage,
        total: meta['total'] as int? ?? items.length,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<ContactModel> getContact(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/api/contacts/$id');
      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response body');
      }
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return ContactModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<ContactModel> createContact(ContactModel contact) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/contacts',
        data: contact.toJson(),
      );
      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response body');
      }
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return ContactModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<ContactModel> updateContact(ContactModel contact) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/contacts/${contact.id}',
        data: contact.toJson(),
      );
      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response body');
      }
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return ContactModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    try {
      await dio.delete<void>('/api/contacts/$id');
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
