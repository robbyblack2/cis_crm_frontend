import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/pipeline_repository.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPipelineRepository extends Mock implements PipelineRepository {}

void main() {
  late MockPipelineRepository mockRepository;

  setUp(() {
    mockRepository = MockPipelineRepository();
  });

  const tPipeline = Pipeline(
    id: '1',
    name: 'Sales Pipeline',
    sortOrder: 0,
    pipelineType: PipelineType.sales,
    isActive: true,
    createdAt: _fixedDate,
  );

  const tStage = Stage(
    id: 's1',
    pipelineId: '1',
    name: 'New',
    position: 0,
    stageType: StageType.normal,
    color: '#FF0000',
  );

  group('PipelineBloc', () {
    test('initial state is PipelineInitial', () {
      final bloc = PipelineBloc(pipelineRepository: mockRepository);
      expect(bloc.state, const PipelineInitial());
      bloc.close();
    });

    group('PipelineLoadRequested', () {
      blocTest<PipelineBloc, PipelineState>(
        'emits [PipelineLoading, PipelineLoaded] when getPipelines succeeds',
        setUp: () {
          when(() => mockRepository.getPipelines())
              .thenAnswer((_) async => const Success([tPipeline]));
        },
        build: () => PipelineBloc(pipelineRepository: mockRepository),
        act: (bloc) => bloc.add(const PipelineLoadRequested()),
        expect: () => const [
          PipelineLoading(),
          PipelineLoaded(pipelines: [tPipeline]),
        ],
        verify: (_) {
          verify(() => mockRepository.getPipelines()).called(1);
        },
      );

      blocTest<PipelineBloc, PipelineState>(
        'emits [PipelineLoading, PipelineError] when getPipelines fails',
        setUp: () {
          when(() => mockRepository.getPipelines()).thenAnswer(
            (_) async => const Failure(ServerFailure('Server error')),
          );
        },
        build: () => PipelineBloc(pipelineRepository: mockRepository),
        act: (bloc) => bloc.add(const PipelineLoadRequested()),
        expect: () => const [
          PipelineLoading(),
          PipelineError(message: 'Server error'),
        ],
      );
    });

    group('PipelineKanbanRequested', () {
      blocTest<PipelineBloc, PipelineState>(
        'emits [PipelineLoading, PipelineLoaded] with kanban data on success',
        setUp: () {
          when(() => mockRepository.getKanban('1')).thenAnswer(
            (_) async => const Success(
              (pipeline: tPipeline, stages: [tStage]),
            ),
          );
        },
        build: () => PipelineBloc(pipelineRepository: mockRepository),
        act: (bloc) => bloc.add(const PipelineKanbanRequested(pipelineId: '1')),
        expect: () => const [
          PipelineLoading(),
          PipelineLoaded(
            pipelines: [],
            kanbanPipeline: tPipeline,
            kanbanStages: [tStage],
          ),
        ],
      );

      blocTest<PipelineBloc, PipelineState>(
        'emits [PipelineLoading, PipelineError] when getKanban fails',
        setUp: () {
          when(() => mockRepository.getKanban('1')).thenAnswer(
            (_) async => const Failure(NetworkFailure()),
          );
        },
        build: () => PipelineBloc(pipelineRepository: mockRepository),
        act: (bloc) => bloc.add(const PipelineKanbanRequested(pipelineId: '1')),
        expect: () => const [
          PipelineLoading(),
          PipelineError(message: 'No internet connection.'),
        ],
      );
    });
  });
}

// Fixed date to avoid const issues with DateTime.
const _fixedDate = _FixedDateTime();

class _FixedDateTime implements DateTime {
  const _FixedDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
