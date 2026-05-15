import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/pipeline/data/datasources/record_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/data/models/record_model.dart';
import 'package:cis_crm/features/pipeline/data/models/stage_transition_model.dart';
import 'package:cis_crm/features/pipeline/data/repositories/record_repository_impl.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecordRemoteDataSource extends Mock
    implements RecordRemoteDataSource {}

void main() {
  late MockRecordRemoteDataSource mockDataSource;
  late RecordRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockRecordRemoteDataSource();
    repository = RecordRepositoryImpl(remoteDataSource: mockDataSource);
  });

  final tNow = DateTime(2024);
  final tRecordModel = RecordModel(
    id: 'r1',
    pipelineId: 'p1',
    stageId: 's1',
    title: 'Test Deal',
    source: RecordSource.manual,
    tags: const ['hot'],
    createdAt: tNow,
    updatedAt: tNow,
  );

  final tTransitionModel = StageTransitionModel(
    id: 't1',
    recordId: 'r1',
    fromStageId: 's1',
    toStageId: 's2',
    transitionedBy: 'user1',
    createdAt: tNow,
  );

  group('getRecords', () {
    test('returns Success with records when data source succeeds', () async {
      when(() => mockDataSource.getRecords())
          .thenAnswer((_) async => [tRecordModel]);

      final result = await repository.getRecords();

      expect(result.isSuccess, true);
      expect(result.dataOrNull, [tRecordModel]);
    });

    test('returns Failure(NetworkFailure) on NetworkException', () async {
      when(() => mockDataSource.getRecords())
          .thenThrow(const NetworkException());

      final result = await repository.getRecords();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('returns Failure(ServerFailure) on ServerException', () async {
      when(() => mockDataSource.getRecords())
          .thenThrow(const ServerException('error'));

      final result = await repository.getRecords();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('getRecord', () {
    test('returns Success when data source succeeds', () async {
      when(() => mockDataSource.getRecord('r1'))
          .thenAnswer((_) async => tRecordModel);

      final result = await repository.getRecord('r1');

      expect(result.isSuccess, true);
      expect(result.dataOrNull, tRecordModel);
    });

    test('returns Failure on ServerException', () async {
      when(() => mockDataSource.getRecord('r1'))
          .thenThrow(const ServerException('not found', statusCode: 404));

      final result = await repository.getRecord('r1');

      expect(result.isFailure, true);
    });
  });

  group('createRecord', () {
    test('returns Success when data source succeeds', () async {
      when(
        () => mockDataSource.createRecord(
          pipelineId: 'p1',
          stageId: 's1',
          title: 'New Deal',
          source: RecordSource.manual,
        ),
      ).thenAnswer((_) async => tRecordModel);

      final result = await repository.createRecord(
        pipelineId: 'p1',
        stageId: 's1',
        title: 'New Deal',
        source: RecordSource.manual,
      );

      expect(result.isSuccess, true);
    });

    test('returns Failure on UnauthorizedException', () async {
      when(
        () => mockDataSource.createRecord(
          pipelineId: 'p1',
          stageId: 's1',
          title: 'New Deal',
          source: RecordSource.manual,
        ),
      ).thenThrow(const UnauthorizedException());

      final result = await repository.createRecord(
        pipelineId: 'p1',
        stageId: 's1',
        title: 'New Deal',
        source: RecordSource.manual,
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('deleteRecord', () {
    test('returns Success when data source succeeds', () async {
      when(() => mockDataSource.deleteRecord('r1')).thenAnswer((_) async {});

      final result = await repository.deleteRecord('r1');

      expect(result.isSuccess, true);
    });

    test('returns Failure on ServerException', () async {
      when(() => mockDataSource.deleteRecord('r1'))
          .thenThrow(const ServerException('delete failed'));

      final result = await repository.deleteRecord('r1');

      expect(result.isFailure, true);
    });
  });

  group('moveRecord', () {
    test('returns Success when data source succeeds', () async {
      when(
        () => mockDataSource.moveRecord(id: 'r1', toStageId: 's2'),
      ).thenAnswer((_) async => tRecordModel);

      final result = await repository.moveRecord(id: 'r1', toStageId: 's2');

      expect(result.isSuccess, true);
    });

    test('returns Failure on NetworkException', () async {
      when(
        () => mockDataSource.moveRecord(id: 'r1', toStageId: 's2'),
      ).thenThrow(const NetworkException());

      final result = await repository.moveRecord(id: 'r1', toStageId: 's2');

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('getStageHistory', () {
    test('returns Success with transitions when data source succeeds',
        () async {
      when(() => mockDataSource.getStageHistory('r1'))
          .thenAnswer((_) async => [tTransitionModel]);

      final result = await repository.getStageHistory('r1');

      expect(result.isSuccess, true);
      expect(result.dataOrNull, [tTransitionModel]);
    });

    test('returns Failure on ServerException', () async {
      when(() => mockDataSource.getStageHistory('r1'))
          .thenThrow(const ServerException('error'));

      final result = await repository.getStageHistory('r1');

      expect(result.isFailure, true);
    });
  });

  group('updateRecord', () {
    test('returns Success when data source succeeds', () async {
      when(
        () => mockDataSource.updateRecord(
          id: 'r1',
          title: 'Updated',
          tags: ['new'],
        ),
      ).thenAnswer((_) async => tRecordModel);

      final result = await repository.updateRecord(
        id: 'r1',
        title: 'Updated',
        tags: ['new'],
      );

      expect(result.isSuccess, true);
    });

    test('returns Failure on ServerException', () async {
      when(
        () => mockDataSource.updateRecord(
          id: 'r1',
          title: 'Updated',
        ),
      ).thenThrow(const ServerException('update failed'));

      final result = await repository.updateRecord(
        id: 'r1',
        title: 'Updated',
      );

      expect(result.isFailure, true);
    });
  });
}
