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
  Future<List<Map<String, dynamic>>> getContactTimeline(String id);
  Future<List<Map<String, dynamic>>> getContactRecords(String id);
  Future<List<Map<String, dynamic>>> getContactNotes(String id);
  Future<Map<String, dynamic>> addContactNote(String id, String body);
  Future<List<Map<String, dynamic>>> getContactFiles(String id);
  Future<List<Map<String, dynamic>>> getContactEmails(String id);
  Future<void> bulkAssign(List<String> ids, String ownerId);
  Future<void> bulkTag(List<String> ids, List<String> tags);
  Future<void> bulkDelete(List<String> ids);
  Future<String> exportContacts();
  Future<void> importContacts(String csvData);
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

  @override
  Future<List<Map<String, dynamic>>> getContactTimeline(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/contacts/$id/timeline',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getContactRecords(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/contacts/$id/records',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getContactNotes(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/contacts/$id/notes',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> addContactNote(
    String id,
    String body,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/contacts/$id/notes',
        data: {'body': body},
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getContactFiles(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/contacts/$id/files',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getContactEmails(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/contacts/$id/emails',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> bulkAssign(List<String> ids, String ownerId) async {
    try {
      await dio.post<void>(
        '/api/contacts/bulk-assign',
        data: {'contact_ids': ids, 'owner_id': ownerId},
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> bulkTag(List<String> ids, List<String> tags) async {
    try {
      await dio.post<void>(
        '/api/contacts/bulk-tag',
        data: {'contact_ids': ids, 'tags': tags},
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> bulkDelete(List<String> ids) async {
    try {
      await dio.post<void>(
        '/api/contacts/bulk-delete',
        data: {'contact_ids': ids},
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<String> exportContacts() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/export/contacts',
      );
      return response.data?['data'] as String? ?? '';
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> importContacts(String csvData) async {
    try {
      await dio.post<void>(
        '/api/import/contacts',
        data: {'csv': csvData},
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  AppException _handleDioException(DioException e) {
    // ErrorInterceptor wraps errors as AppException in e.error
    final wrapped = e.error;
    if (wrapped is AppException) return wrapped;

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
