import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/record_repository.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formz/formz.dart';
import 'package:mocktail/mocktail.dart';

class MockRecordRepository extends Mock implements RecordRepository {}

void main() {
  late MockRecordRepository mockRepo;

  final now = DateTime(2024);
  final testRecord = PipelineRecord(
    id: 'r1',
    pipelineId: 'p1',
    stageId: 's1',
    title: 'Test Deal',
    source: RecordSource.manual,
    tags: const [],
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(RecordSource.manual);
  });

  setUp(() {
    mockRepo = MockRecordRepository();
  });

  group('RecordFormCubit', () {
    test('initial state has empty title', () {
      final cubit = RecordFormCubit(recordRepository: mockRepo);
      expect(cubit.state.title.value, isEmpty);
      expect(cubit.state.submissionStatus, FormzSubmissionStatus.initial);
      cubit.close();
    });

    blocTest<RecordFormCubit, RecordFormState>(
      'submitted calls createRecord and emits success',
      setUp: () {
        when(
          () => mockRepo.createRecord(
            pipelineId: any(named: 'pipelineId'),
            stageId: any(named: 'stageId'),
            title: any(named: 'title'),
            source: any(named: 'source'),
          ),
        ).thenAnswer((_) async => Success(testRecord));
      },
      build: () => RecordFormCubit(recordRepository: mockRepo),
      act: (cubit) {
        cubit
          ..titleChanged('Test Deal')
          ..pipelineIdChanged('p1')
          ..stageIdChanged('s1');
        return cubit.submitted();
      },
      expect: () => [
        isA<RecordFormState>(), // title dirty
        isA<RecordFormState>(), // pipelineId
        isA<RecordFormState>(), // stageId
        isA<RecordFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.inProgress,
            ),
        isA<RecordFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.success,
            ),
      ],
      verify: (_) {
        verify(
          () => mockRepo.createRecord(
            pipelineId: any(named: 'pipelineId'),
            stageId: any(named: 'stageId'),
            title: any(named: 'title'),
            source: any(named: 'source'),
          ),
        ).called(1);
      },
    );

    blocTest<RecordFormCubit, RecordFormState>(
      'submitted emits failure when repo fails',
      setUp: () {
        when(
          () => mockRepo.createRecord(
            pipelineId: any(named: 'pipelineId'),
            stageId: any(named: 'stageId'),
            title: any(named: 'title'),
            source: any(named: 'source'),
          ),
        ).thenAnswer(
          (_) async => const Failure(ServerFailure('Failed')),
        );
      },
      build: () => RecordFormCubit(recordRepository: mockRepo),
      act: (cubit) {
        cubit.titleChanged('Deal');
        return cubit.submitted();
      },
      expect: () => [
        isA<RecordFormState>(), // title dirty
        isA<RecordFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.inProgress,
            ),
        isA<RecordFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.failure,
            ),
      ],
    );

    blocTest<RecordFormCubit, RecordFormState>(
      'submitted emits failure when title is empty',
      build: () => RecordFormCubit(recordRepository: mockRepo),
      act: (cubit) => cubit.submitted(),
      expect: () => [
        isA<RecordFormState>(), // validation
        isA<RecordFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.failure,
            ),
      ],
      verify: (_) {
        verifyNever(
          () => mockRepo.createRecord(
            pipelineId: any(named: 'pipelineId'),
            stageId: any(named: 'stageId'),
            title: any(named: 'title'),
            source: any(named: 'source'),
          ),
        );
      },
    );
  });
}
