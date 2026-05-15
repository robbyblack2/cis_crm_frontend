import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/files/data/models/file_attachment_model.dart';
import 'package:dio/dio.dart';

abstract interface class FileRemoteDatasource {
  Future<FileAttachmentModel> upload({
    required String parentType,
    required String parentId,
    required String filePath,
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
      return FileAttachmentModel.fromJson(response.data!);
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
      return FileAttachmentModel.fromJson(response.data!);
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
      return response.data!['url'] as String;
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
