import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/files/data/datasources/file_remote_datasource.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:cis_crm/features/files/domain/repositories/file_repository.dart';

class FileRepositoryImpl implements FileRepository {
  const FileRepositoryImpl({required FileRemoteDatasource datasource})
      : _datasource = datasource;

  final FileRemoteDatasource _datasource;

  @override
  Future<Result<List<FileAttachment>, AppFailure>> getFilesByParent({
    required String parentType,
    required String parentId,
  }) async {
    return _guard(
      () => _datasource.getFilesByParent(
        parentType: parentType,
        parentId: parentId,
      ),
    );
  }

  @override
  Future<Result<FileAttachment, AppFailure>> upload({
    required String parentType,
    required String parentId,
    required String filePath,
    required String filename,
  }) async {
    return _guard(
      () => _datasource.upload(
        parentType: parentType,
        parentId: parentId,
        filePath: filePath,
        filename: filename,
      ),
    );
  }

  @override
  Future<Result<FileAttachment, AppFailure>> uploadBytes({
    required String parentType,
    required String parentId,
    required List<int> bytes,
    required String filename,
  }) async {
    return _guard(
      () => _datasource.uploadBytes(
        parentType: parentType,
        parentId: parentId,
        bytes: bytes,
        filename: filename,
      ),
    );
  }

  @override
  Future<Result<FileAttachment, AppFailure>> getMetadata(String id) async {
    return _guard(() => _datasource.getMetadata(id));
  }

  @override
  Future<Result<List<int>, AppFailure>> download(String id) async {
    return _guard(() => _datasource.download(id));
  }

  @override
  Future<Result<String, AppFailure>> getPreviewUrl(String id) async {
    return _guard(() => _datasource.getPreviewUrl(id));
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) async {
    return _guard(() => _datasource.delete(id));
  }

  Future<Result<T, AppFailure>> _guard<T>(
    Future<T> Function() call,
  ) async {
    try {
      final result = await call();
      return Success(result);
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Failure(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }
}
