import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:cis_crm/features/files/domain/repositories/file_repository.dart';
import 'package:cis_crm/features/files/presentation/cubit/files_cubit.dart';
import 'package:cis_crm/features/files/presentation/cubit/files_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFileRepository extends Mock implements FileRepository {}

void main() {
  late MockFileRepository mockRepository;

  final tFile = FileAttachment(
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
    mockRepository = MockFileRepository();
  });

  group('FilesCubit', () {
    test('initial state is FilesInitial', () {
      final cubit = FilesCubit(repository: mockRepository);
      expect(cubit.state, const FilesInitial());
      cubit.close();
    });

    group('loadFile', () {
      blocTest<FilesCubit, FilesState>(
        'emits [FilesLoading, FilesLoaded] on success',
        setUp: () {
          when(() => mockRepository.getMetadata(any()))
              .thenAnswer((_) async => Success(tFile));
        },
        build: () => FilesCubit(repository: mockRepository),
        act: (cubit) => cubit.loadFile('1'),
        expect: () => [
          const FilesLoading(),
          FilesLoaded([tFile]),
        ],
      );

      blocTest<FilesCubit, FilesState>(
        'emits [FilesLoading, FilesError] on failure',
        setUp: () {
          when(() => mockRepository.getMetadata(any())).thenAnswer(
            (_) async => const Failure(ServerFailure('fail', statusCode: 500)),
          );
        },
        build: () => FilesCubit(repository: mockRepository),
        act: (cubit) => cubit.loadFile('1'),
        expect: () => [
          const FilesLoading(),
          const FilesError(ServerFailure('fail', statusCode: 500)),
        ],
      );
    });

    group('uploadFile', () {
      blocTest<FilesCubit, FilesState>(
        'emits [FilesUploading, FilesLoaded] on success',
        setUp: () {
          when(
            () => mockRepository.upload(
              parentType: any(named: 'parentType'),
              parentId: any(named: 'parentId'),
              filePath: any(named: 'filePath'),
              filename: any(named: 'filename'),
            ),
          ).thenAnswer((_) async => Success(tFile));
        },
        build: () => FilesCubit(repository: mockRepository),
        act: (cubit) => cubit.uploadFile(
          parentType: 'contact',
          parentId: 'c1',
          filePath: '/tmp/test.pdf',
          filename: 'test.pdf',
        ),
        expect: () => [
          const FilesUploading([]),
          FilesLoaded([tFile]),
        ],
      );

      blocTest<FilesCubit, FilesState>(
        'emits [FilesUploading, FilesError] on failure',
        setUp: () {
          when(
            () => mockRepository.upload(
              parentType: any(named: 'parentType'),
              parentId: any(named: 'parentId'),
              filePath: any(named: 'filePath'),
              filename: any(named: 'filename'),
            ),
          ).thenAnswer(
            (_) async => const Failure(ServerFailure('upload failed')),
          );
        },
        build: () => FilesCubit(repository: mockRepository),
        act: (cubit) => cubit.uploadFile(
          parentType: 'contact',
          parentId: 'c1',
          filePath: '/tmp/test.pdf',
          filename: 'test.pdf',
        ),
        expect: () => [
          const FilesUploading([]),
          const FilesError(ServerFailure('upload failed')),
        ],
      );
    });

    group('deleteFile', () {
      blocTest<FilesCubit, FilesState>(
        'emits [FilesLoaded] with file removed on success',
        setUp: () {
          when(() => mockRepository.delete(any()))
              .thenAnswer((_) async => const Success(null));
        },
        build: () => FilesCubit(repository: mockRepository),
        seed: () => FilesLoaded([tFile]),
        act: (cubit) => cubit.deleteFile('1'),
        expect: () => [
          const FilesLoaded([]),
        ],
      );

      blocTest<FilesCubit, FilesState>(
        'emits [FilesError] on failure',
        setUp: () {
          when(() => mockRepository.delete(any())).thenAnswer(
            (_) async => const Failure(ServerFailure('delete failed')),
          );
        },
        build: () => FilesCubit(repository: mockRepository),
        seed: () => FilesLoaded([tFile]),
        act: (cubit) => cubit.deleteFile('1'),
        expect: () => [
          const FilesError(ServerFailure('delete failed')),
        ],
      );
    });
  });
}
