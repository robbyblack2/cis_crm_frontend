import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/contacts/data/models/contact_model.dart';
import 'package:dio/dio.dart';

abstract class ContactRemoteDataSource {
  Future<List<ContactModel>> getContacts();
  Future<ContactModel> getContact(String id);
  Future<ContactModel> createContact(ContactModel contact);
  Future<ContactModel> updateContact(ContactModel contact);
  Future<void> deleteContact(String id);
}

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  ContactRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<List<ContactModel>> getContacts() async {
    try {
      final response = await dio.get<List<dynamic>>('/api/contacts');
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return data
          .cast<Map<String, dynamic>>()
          .map(ContactModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<ContactModel> getContact(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/api/contacts/$id');
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
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
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
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
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
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
