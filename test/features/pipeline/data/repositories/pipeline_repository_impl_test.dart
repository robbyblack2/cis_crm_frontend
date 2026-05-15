import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/pipeline/data/datasources/pipeline_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/data/models/pipeline_model.dart';
import 'package:cis_crm/features/pipeline/data/models/stage_model.dart';
import 'package:cis_crm/features/pipeline/data/repositories/pipeline_repository_impl.dart';
import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPipelineRemoteDataSource extends Mock
    implements PipelineRemoteDataSource {}

void main() {
  late MockPipelineRemoteDataSource mockDataSource;
  late PipelineRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockPipelineRemoteDataSource();
    repository = PipelineRepositoryImpl(remoteDataSource: mockDataSource);
  });

  final tNow = DateTime(2024);
  final tPipelineModel = PipelineModel(
    id: '1',
    name: 'Sales',
    sortOrder: 0,
    pipelineType: PipelineType.sales,
    isActive: true,
    createdAt: tNow,
  );

  const tStageModel = StageModel(
    id: 's1',
    pipelineId: '1',
    name: 'New',
    position: 0,
    stageType: StageType.normal,
    color: '#FF0000',
  );

  group('getPipelines', () {
    test('returns Success with pipelines when data source succeeds', () async {
      when(() => mockDataSource.getPipelines())
          .thenAnswer((_) async => [tPipelineModel]);

      final result = await repository.getPipelines();

      expect(result.isSuccess, true);
      expect(result.dataOrNull, [tPipelineModel]);
      verify(() => mockDataSource.getPipelines()).called(1);
    });

    test('returns Failure(NetworkFailure) on NetworkException', () async {
      when(() => mockDataSource.getPipelines())
          .thenThrow(const NetworkException());

      final result = await repository.getPipelines();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('returns Failure(ServerFailure) on ServerException', () async {
      when(() => mockDataSource.getPipelines())
          .thenThrow(const ServerException('error', statusCode: 500));

      final result = await repository.getPipelines();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull!.message, 'error');
    });

    test('returns Failure(UnauthorizedFailure) on UnauthorizedException',
        () async {
      when(() => mockDataSource.getPipelines())
          .thenThrow(const UnauthorizedException());

      final result = await repository.getPipelines();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('getKanban', () {
    test('returns Success with kanban data when data source succeeds',
        () async {
      when(() => mockDataSource.getKanban('1')).thenAnswer(
        (_) async => (pipeline: tPipelineModel, stages: [tStageModel]),
      );

      final result = await repository.getKanban('1');

      expect(result.isSuccess, true);
      final data = result.dataOrNull!;
      expect(data.pipeline, tPipelineModel);
      expect(data.stages, [tStageModel]);
    });

    test('returns Failure on ServerException', () async {
      when(() => mockDataSource.getKanban('1'))
          .thenThrow(const ServerException('not found', statusCode: 404));

      final result = await repository.getKanban('1');

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('createPipeline', () {
    test('returns Success when data source succeeds', () async {
      when(
        () => mockDataSource.createPipeline(
          name: 'Sales',
          pipelineType: PipelineType.sales,
        ),
      ).thenAnswer((_) async => tPipelineModel);

      final result = await repository.createPipeline(
        name: 'Sales',
        pipelineType: PipelineType.sales,
      );

      expect(result.isSuccess, true);
      expect(result.dataOrNull, tPipelineModel);
    });

    test('returns Failure on ServerException', () async {
      when(
        () => mockDataSource.createPipeline(
          name: 'Sales',
          pipelineType: PipelineType.sales,
        ),
      ).thenThrow(const ServerException('create failed'));

      final result = await repository.createPipeline(
        name: 'Sales',
        pipelineType: PipelineType.sales,
      );

      expect(result.isFailure, true);
    });
  });

  group('updatePipeline', () {
    test('returns Success when data source succeeds', () async {
      when(
        () => mockDataSource.updatePipeline(
          id: '1',
          name: 'Updated',
          isActive: false,
        ),
      ).thenAnswer((_) async => tPipelineModel);

      final result = await repository.updatePipeline(
        id: '1',
        name: 'Updated',
        isActive: false,
      );

      expect(result.isSuccess, true);
    });

    test('returns Failure on NetworkException', () async {
      when(
        () => mockDataSource.updatePipeline(
          id: '1',
          name: 'Updated',
          isActive: false,
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.updatePipeline(
        id: '1',
        name: 'Updated',
        isActive: false,
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });
}
