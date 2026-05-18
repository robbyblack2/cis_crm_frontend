import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/files/data/datasources/file_remote_datasource.dart';
import 'package:cis_crm/features/files/data/models/file_attachment_model.dart';
import 'package:cis_crm/features/files/data/repositories/file_repository_impl.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFileRemoteDatasource extends Mock implements FileRemoteDatasource {}

void main() {
  late MockFileRemoteDatasource mockDatasource;
  late FileRepositoryImpl repository;

  final tModel = FileAttachmentModel(
    id: '1',
    filename: 'test.pdf',
    contentType: 'application/pdf',
    sizeBytes: 1024,
    s3Key: 'files/1/test.pdf',
    contentHash: 'abc123',
    parentType: 'contact',
    parentId: 'c1',
    uploadedBy: 'u1',
    createdAt: DateTime.utc(2026),
  );

  setUp(() {
    mockDatasource = MockFileRemoteDatasource();
    repository = FileRepositoryImpl(datasource: mockDatasource);
  });

  group('getFilesByParent', () {
    test('returns Success with list on datasource success', () async {
      when(
        () => mockDatasource.getFilesByParent(
          parentType: any(named: 'parentType'),
          parentId: any(named: 'parentId'),
        ),
      ).thenAnswer((_) async => [tModel]);

      final result = await repository.getFilesByParent(
        parentType: 'contact',
        parentId: 'c1',
      );

      expect(result, isA<Success<List<FileAttachment>, AppFailure>>());
      expect(result.dataOrNull, [tModel]);
    });

    test('returns Failure(ServerFailure) on ServerException', () async {
      when(
        () => mockDatasource.getFilesByParent(
          parentType: any(named: 'parentType'),
          parentId: any(named: 'parentId'),
        ),
      ).thenThrow(const ServerException('fail', statusCode: 500));

      final result = await repository.getFilesByParent(
        parentType: 'contact',
        parentId: 'c1',
      );

      expect(result, isA<Failure<List<FileAttachment>, AppFailure>>());
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('getMetadata', () {
    test('returns Success with FileAttachment on datasource success', () async {
      when(() => mockDatasource.getMetadata(any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.getMetadata('1');

      expect(result, isA<Success<FileAttachment, AppFailure>>());
      expect(result.dataOrNull, tModel);
    });

    test('returns Failure(ServerFailure) on ServerException', () async {
      when(() => mockDatasource.getMetadata(any()))
          .thenThrow(const ServerException('fail', statusCode: 500));

      final result = await repository.getMetadata('1');

      expect(result, isA<Failure<FileAttachment, AppFailure>>());
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('returns Failure(NetworkFailure) on NetworkException', () async {
      when(() => mockDatasource.getMetadata(any()))
          .thenThrow(const NetworkException());

      final result = await repository.getMetadata('1');

      expect(result, isA<Failure<FileAttachment, AppFailure>>());
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('returns Failure(UnauthorizedFailure) on UnauthorizedException',
        () async {
      when(() => mockDatasource.getMetadata(any()))
          .thenThrow(const UnauthorizedException());

      final result = await repository.getMetadata('1');

      expect(result, isA<Failure<FileAttachment, AppFailure>>());
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('delete', () {
    test('returns Success(void) on datasource success', () async {
      when(() => mockDatasource.delete(any())).thenAnswer((_) async {});

      final result = await repository.delete('1');

      expect(result, isA<Success<void, AppFailure>>());
    });

    test('returns Failure on ServerException', () async {
      when(() => mockDatasource.delete(any()))
          .thenThrow(const ServerException('fail'));

      final result = await repository.delete('1');

      expect(result, isA<Failure<void, AppFailure>>());
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('download', () {
    test('returns Success with bytes on success', () async {
      when(() => mockDatasource.download(any()))
          .thenAnswer((_) async => [1, 2, 3]);

      final result = await repository.download('1');

      expect(result.dataOrNull, [1, 2, 3]);
    });
  });

  group('getPreviewUrl', () {
    test('returns Success with url on success', () async {
      when(() => mockDatasource.getPreviewUrl(any()))
          .thenAnswer((_) async => 'https://example.com');

      final result = await repository.getPreviewUrl('1');

      expect(result.dataOrNull, 'https://example.com');
    });
  });

  group('upload', () {
    test('returns Success with FileAttachment on success', () async {
      when(
        () => mockDatasource.upload(
          parentType: any(named: 'parentType'),
          parentId: any(named: 'parentId'),
          filePath: any(named: 'filePath'),
          filename: any(named: 'filename'),
        ),
      ).thenAnswer((_) async => tModel);

      final result = await repository.upload(
        parentType: 'contact',
        parentId: 'c1',
        filePath: '/tmp/test.pdf',
        filename: 'test.pdf',
      );

      expect(result, isA<Success<FileAttachment, AppFailure>>());
      expect(result.dataOrNull, tModel);
    });
  });
}
