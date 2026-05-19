import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/record_repository.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecordRepository extends Mock implements RecordRepository {}

void main() {
  late MockRecordRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(RecordSource.manual);
  });

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

  final tPaginatedResponse = PaginatedResponse<PipelineRecord>(
    items: [tRecord],
    page: 1,
    perPage: 25,
    total: 1,
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
              .thenAnswer((_) async => Success(tPaginatedResponse));
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(const RecordLoadRequested()),
        expect: () => [
          const RecordLoading(),
          RecordLoaded(
            records: [tRecord],
            currentPage: 1,
            total: 1,
          ),
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

    group('RecordLoadMoreRequested', () {
      final tRecord2 = PipelineRecord(
        id: 'r2',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Another Deal',
        source: RecordSource.manual,
        tags: const [],
        createdAt: tNow,
        updatedAt: tNow,
      );

      final tPage2Response = PaginatedResponse<PipelineRecord>(
        items: [tRecord2],
        page: 2,
        perPage: 25,
        total: 50,
      );

      blocTest<RecordBloc, RecordState>(
        'appends items when load more succeeds',
        seed: () => RecordLoaded(
          records: [tRecord],
          currentPage: 1,
          total: 50,
          perPage: 25,
        ),
        setUp: () {
          when(() => mockRepository.getRecords(page: 2, perPage: 25))
              .thenAnswer((_) async => Success(tPage2Response));
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(const RecordLoadMoreRequested()),
        expect: () => [
          RecordLoaded(
            records: [tRecord],
            currentPage: 1,
            total: 50,
            perPage: 25,
            isLoadingMore: true,
          ),
          RecordLoaded(
            records: [tRecord, tRecord2],
            currentPage: 2,
            total: 50,
            perPage: 25,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getRecords(page: 2, perPage: 25))
              .called(1);
        },
      );

      blocTest<RecordBloc, RecordState>(
        'does nothing when there are no more pages',
        seed: () => RecordLoaded(
          records: [tRecord],
          currentPage: 1,
          total: 1,
          perPage: 25,
        ),
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(const RecordLoadMoreRequested()),
        expect: () => <RecordState>[],
      );

      blocTest<RecordBloc, RecordState>(
        'does nothing when state is not RecordLoaded',
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(const RecordLoadMoreRequested()),
        expect: () => <RecordState>[],
      );
    });

    group('RecordCreateRequested', () {
      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordLoaded] when create + reload succeeds',
        setUp: () {
          when(
            () => mockRepository.createRecord(
              pipelineId: any(named: 'pipelineId'),
              stageId: any(named: 'stageId'),
              title: any(named: 'title'),
              source: any(named: 'source'),
              contactId: any(named: 'contactId'),
              companyId: any(named: 'companyId'),
              tags: any(named: 'tags'),
            ),
          ).thenAnswer((_) async => Success(tRecord));
          when(() => mockRepository.getRecords())
              .thenAnswer((_) async => Success(tPaginatedResponse));
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
          RecordLoaded(
            records: [tRecord],
            currentPage: 1,
            total: 1,
          ),
        ],
      );

      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordError] when create fails',
        setUp: () {
          when(
            () => mockRepository.createRecord(
              pipelineId: any(named: 'pipelineId'),
              stageId: any(named: 'stageId'),
              title: any(named: 'title'),
              source: any(named: 'source'),
              contactId: any(named: 'contactId'),
              companyId: any(named: 'companyId'),
              tags: any(named: 'tags'),
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

    group('RecordUpdateRequested', () {
      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordLoaded] when update + reload succeeds',
        setUp: () {
          when(
            () => mockRepository.updateRecord(
              id: 'r1',
              title: 'Updated Deal',
            ),
          ).thenAnswer((_) async => Success(tRecord));
          when(() => mockRepository.getRecords())
              .thenAnswer((_) async => Success(tPaginatedResponse));
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(
          const RecordUpdateRequested(
            id: 'r1',
            title: 'Updated Deal',
          ),
        ),
        expect: () => [
          const RecordLoading(),
          RecordLoaded(
            records: [tRecord],
            currentPage: 1,
            total: 1,
          ),
        ],
      );

      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordError] when update fails',
        setUp: () {
          when(
            () => mockRepository.updateRecord(
              id: 'r1',
              title: 'Updated Deal',
            ),
          ).thenAnswer(
            (_) async => const Failure(ServerFailure('Update failed')),
          );
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(
          const RecordUpdateRequested(
            id: 'r1',
            title: 'Updated Deal',
          ),
        ),
        expect: () => const [
          RecordLoading(),
          RecordError(message: 'Update failed'),
        ],
      );
    });

    group('RecordDeleteRequested', () {
      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordLoaded] when delete + reload succeeds',
        setUp: () {
          when(() => mockRepository.deleteRecord('r1'))
              .thenAnswer((_) async => const Success(null));
          when(() => mockRepository.getRecords())
              .thenAnswer((_) async => Success(tPaginatedResponse));
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(
          const RecordDeleteRequested(recordId: 'r1'),
        ),
        expect: () => [
          const RecordLoading(),
          RecordLoaded(
            records: [tRecord],
            currentPage: 1,
            total: 1,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.deleteRecord('r1')).called(1);
        },
      );

      blocTest<RecordBloc, RecordState>(
        'emits [RecordLoading, RecordError] when delete fails',
        setUp: () {
          when(() => mockRepository.deleteRecord('r1')).thenAnswer(
            (_) async => const Failure(ServerFailure('Delete failed')),
          );
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(
          const RecordDeleteRequested(recordId: 'r1'),
        ),
        expect: () => const [
          RecordLoading(),
          RecordError(message: 'Delete failed'),
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
              .thenAnswer((_) async => Success(tPaginatedResponse));
        },
        build: () => RecordBloc(recordRepository: mockRepository),
        act: (bloc) => bloc.add(
          const RecordMoveRequested(recordId: 'r1', toStageId: 's2'),
        ),
        expect: () => [
          const RecordLoading(),
          RecordLoaded(
            records: [tRecord],
            currentPage: 1,
            total: 1,
          ),
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
