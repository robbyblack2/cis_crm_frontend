import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/record_repository.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecordRepository extends Mock implements RecordRepository {}

void main() {
  late MockRecordRepository mockRepository;

  setUp(() {
    mockRepository = MockRecordRepository();
  });

  final tNow = DateTime(2024);
  final tRecord = PipelineRecord(
    id: 'r1',
    pipelineId: 'p1',
    stageId: 's1',
    title: 'Test Deal',
    source: RecordSource.manual,
    tags: const ['hot'],
    createdAt: tNow,
    updatedAt: tNow,
  );

  group('RecordBloc', () {
    test('initial state is RecordInitial', () {
      final bloc = RecordBloc(recordRepository: mockRepository);
      expect(bloc.state, const RecordInitial());
      bloc.close();
    });

    group('RecordLoadRequested', () {
      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordLoaded] when getRecords succeeds',
        setUp: () {
          when(() => mockRepository.getRecords())
              .thenAnswer((_) async => Success([tRecord]));
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(const RecordLoadRequested()),
        expect: () => [
          const RecordLoading(),
          RecordLoaded(records: [tRecord]),
        ],
        verify: (_) {
          verify(() => mockRepository.getRecords()).called(1);
        },
      );

      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordError] when getRecords fails',
        setUp: () {
          when(() => mockRepository.getRecords()).thenAnswer(
            (_) async => const Failure(ServerFailure('Server error')),
          );
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(const RecordLoadRequested()),
        expect: () => const [
          RecordLoading(),
          RecordError(message: 'Server error'),
        ],
      );
    });

    group('RecordCreateRequested', () {
      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordLoaded] when create + reload succeeds',
        setUp: () {
          when(
            () => mockRepository.createRecord(
              pipelineId: 'p1',
              stageId: 's1',
              title: 'New Deal',
              source: RecordSource.manual,
            ),
          ).thenAnswer((_) async => Success(tRecord));
          when(() => mockRepository.getRecords())
              .thenAnswer((_) async => Success([tRecord]));
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(
          const RecordCreateRequested(
            pipelineId: 'p1',
            stageId: 's1',
            title: 'New Deal',
            source: RecordSource.manual,
          ),
        ),
        expect: () => [
          const RecordLoading(),
          RecordLoaded(records: [tRecord]),
        ],
      );

      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordError] when create fails',
        setUp: () {
          when(
            () => mockRepository.createRecord(
              pipelineId: 'p1',
              stageId: 's1',
              title: 'New Deal',
              source: RecordSource.manual,
            ),
          ).thenAnswer(
            (_) async => const Failure(ServerFailure('Create failed')),
          );
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(
          const RecordCreateRequested(
            pipelineId: 'p1',
            stageId: 's1',
            title: 'New Deal',
            source: RecordSource.manual,
          ),
        ),
        expect: () => const [
          RecordLoading(),
          RecordError(message: 'Create failed'),
        ],
      );
    });

    group('RecordMoveRequested', () {
      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordLoaded] when move + reload succeeds',
        setUp: () {
          when(
            () => mockRepository.moveRecord(id: 'r1', toStageId: 's2'),
          ).thenAnswer((_) async => Success(tRecord));
          when(() => mockRepository.getRecords())
              .thenAnswer((_) async => Success([tRecord]));
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(
          const RecordMoveRequested(recordId: 'r1', toStageId: 's2'),
        ),
        expect: () => [
          const RecordLoading(),
          RecordLoaded(records: [tRecord]),
        ],
      );

      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordError] when move fails',
        setUp: () {
          when(
            () => mockRepository.moveRecord(id: 'r1', toStageId: 's2'),
          ).thenAnswer(
            (_) async => const Failure(NetworkFailure()),
          );
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(
          const RecordMoveRequested(recordId: 'r1', toStageId: 's2'),
        ),
        expect: () => const [
          RecordLoading(),
          RecordError(message: 'No internet connection.'),
        ],
      );
    });
  });
}
