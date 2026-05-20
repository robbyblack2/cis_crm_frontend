import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/files/data/models/file_attachment_model.dart';
import 'package:dio/dio.dart';

abstract interface class FileRemoteDatasource {
  Future<List<FileAttachmentModel>> getFilesByParent({
    required String parentType,
    required String parentId,
  });

  Future<FileAttachmentModel> upload({
    required String parentType,
    required String parentId,
    required String filePath,
    required String filename,
  });

  Future<FileAttachmentModel> uploadBytes({
    required String parentType,
    required String parentId,
    required List<int> bytes,
    required String filename,
  });

  Future<FileAttachmentModel> getMetadata(String id);

  Future<List<int>> download(String id);

  Future<String> getPreviewUrl(String id);

  Future<void> delete(String id);
}

class FileRemoteDatasourceImpl implements FileRemoteDatasource {
  const FileRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<FileAttachmentModel>> getFilesByParent({
    required String parentType,
    required String parentId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/files',
        queryParameters: {
          'parent_type': parentType,
          'parent_id': parentId,
        },
      );
      final items = response.data?['data'] as List<dynamic>?;
      if (items == null) return [];
      return items
          .cast<Map<String, dynamic>>()
          .map(FileAttachmentModel.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw ServerException(e.message ?? 'Failed to list files.');
    }
  }

  @override
  Future<FileAttachmentModel> upload({
    required String parentType,
    required String parentId,
    required String filePath,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'parent_type': parentType,
        'parent_id': parentId,
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/files/upload',
        data: formData,
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response');
      }
      return FileAttachmentModel.fromJson(data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw ServerException(e.message ?? 'Upload failed.');
    }
  }

  @override
  Future<FileAttachmentModel> uploadBytes({
    required String parentType,
    required String parentId,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'parent_type': parentType,
        'parent_id': parentId,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/files/upload',
        data: formData,
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response');
      }
      return FileAttachmentModel.fromJson(data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw ServerException(e.message ?? 'Upload failed.');
    }
  }

  @override
  Future<FileAttachmentModel> getMetadata(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/files/$id',
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response');
      }
      return FileAttachmentModel.fromJson(data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw ServerException(e.message ?? 'Failed to fetch metadata.');
    }
  }

  @override
  Future<List<int>> download(String id) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/files/$id/download',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw ServerException(e.message ?? 'Download failed.');
    }
  }

  @override
  Future<String> getPreviewUrl(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/files/$id/preview',
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response');
      }
      return data['url'] as String;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw ServerException(e.message ?? 'Preview failed.');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/api/files/$id');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw ServerException(e.message ?? 'Delete failed.');
    }
  }
}
