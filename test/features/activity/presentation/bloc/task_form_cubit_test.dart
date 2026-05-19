import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/task_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formz/formz.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class FakeCrmTask extends Fake implements CrmTask {}

void main() {
  late MockTaskRepository mockRepo;

  final now = DateTime(2024);
  final testTask = CrmTask(
    id: 't1',
    title: 'Test Task',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    parentType: 'general',
    parentId: '',
    createdBy: '',
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(FakeCrmTask());
  });

  setUp(() {
    mockRepo = MockTaskRepository();
  });

  group('TaskFormCubit', () {
    test('initial state has empty title', () {
      final cubit = TaskFormCubit(taskRepository: mockRepo);
      expect(cubit.state.title.value, isEmpty);
      expect(cubit.state.submissionStatus, FormzSubmissionStatus.initial);
      cubit.close();
    });

    blocTest<TaskFormCubit, TaskFormState>(
      'submitted calls createTask and emits success',
      setUp: () {
        when(() => mockRepo.createTask(any()))
            .thenAnswer((_) async => Success(testTask));
      },
      build: () => TaskFormCubit(taskRepository: mockRepo),
      act: (cubit) {
        cubit.titleChanged('Test Task');
        return cubit.submitted();
      },
      expect: () => [
        isA<TaskFormState>(), // title dirty
        isA<TaskFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.inProgress,
            ),
        isA<TaskFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.success,
            ),
      ],
      verify: (_) {
        verify(() => mockRepo.createTask(any())).called(1);
      },
    );

    blocTest<TaskFormCubit, TaskFormState>(
      'submitted emits failure when repo fails',
      setUp: () {
        when(() => mockRepo.createTask(any()))
            .thenAnswer((_) async => const Failure(ServerFailure('Failed')));
      },
      build: () => TaskFormCubit(taskRepository: mockRepo),
      act: (cubit) {
        cubit.titleChanged('Test');
        return cubit.submitted();
      },
      expect: () => [
        isA<TaskFormState>(), // title dirty
        isA<TaskFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.inProgress,
            ),
        isA<TaskFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.failure,
            ),
      ],
    );

    blocTest<TaskFormCubit, TaskFormState>(
      'submitted emits failure when title is empty',
      build: () => TaskFormCubit(taskRepository: mockRepo),
      act: (cubit) => cubit.submitted(),
      expect: () => [
        isA<TaskFormState>(), // validation
        isA<TaskFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.failure,
            ),
      ],
      verify: (_) {
        verifyNever(() => mockRepo.createTask(any()));
      },
    );
  });
}
