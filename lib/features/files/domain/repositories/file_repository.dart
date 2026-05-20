import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';

abstract interface class FileRepository {
  Future<Result<List<FileAttachment>, AppFailure>> getFilesByParent({
    required String parentType,
    required String parentId,
  });

  Future<Result<FileAttachment, AppFailure>> upload({
    required String parentType,
    required String parentId,
    required String filePath,
    required String filename,
  });

  Future<Result<FileAttachment, AppFailure>> uploadBytes({
    required String parentType,
    required String parentId,
    required List<int> bytes,
    required String filename,
  });

  Future<Result<FileAttachment, AppFailure>> getMetadata(String id);

  Future<Result<List<int>, AppFailure>> download(String id);

  Future<Result<String, AppFailure>> getPreviewUrl(String id);

  Future<Result<void, AppFailure>> delete(String id);
}
