import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/example_model.dart';

/// Remote data source — talks to the API. Throws typed [AppException]s
/// on failure. The repository catches those and converts to [AppFailure].
abstract interface class ExampleRemoteDataSource {
  Future<List<ExampleModel>> getAll();
  Future<ExampleModel> getById(String id);
  Future<ExampleModel> create(ExampleModel model);
  Future<void> delete(String id);
}

class ExampleRemoteDataSourceImpl implements ExampleRemoteDataSource {
  ExampleRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const _path = '/examples';

  @override
  Future<List<ExampleModel>> getAll() async {
    try {
      final response = await _dio.get<List<dynamic>>(_path);
      final data = response.data ?? const [];
      return data
          .cast<Map<String, dynamic>>()
          .map(ExampleModel.fromJson)
          .toList();
    } on DioException catch (e) {
      // ErrorInterceptor has already wrapped to an AppException in e.error.
      if (e.error is AppException) throw e.error! as AppException;
      throw NetworkException(e.message ?? 'Network error.');
    } catch (e) {
      throw ServerException('Failed to parse response: $e');
    }
  }

  @override
  Future<ExampleModel> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
      if (response.data == null) {
        throw const ServerException('Empty response body.');
      }
      return ExampleModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw NetworkException(e.message ?? 'Network error.');
    }
  }

  @override
  Future<ExampleModel> create(ExampleModel model) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _path,
        data: model.toJson(),
      );
      if (response.data == null) {
        throw const ServerException('Empty response body.');
      }
      return ExampleModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw NetworkException(e.message ?? 'Network error.');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('$_path/$id');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error! as AppException;
      throw NetworkException(e.message ?? 'Network error.');
    }
  }
}
