import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class FakeCrmTask extends Fake implements CrmTask {}

void main() {
  late MockTaskRepository mockRepo;

  final now = DateTime(2024);
  final testTask = CrmTask(
    id: '1',
    title: 'Test task',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    parentType: 'contact',
    parentId: 'c1',
    createdBy: 'user1',
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(FakeCrmTask());
  });

  setUp(() {
    mockRepo = MockTaskRepository();
  });

  group('TasksBloc', () {
    test('initial state is TasksInitial', () {
      final bloc = TasksBloc(taskRepository: mockRepo);
      expect(bloc.state, const TasksInitial());
      bloc.close();
    });

    blocTest<TasksBloc, TasksState>(
      'emits [Loading, Loaded] when TasksLoadRequested succeeds',
      build: () {
        when(() => mockRepo.getTasks())
            .thenAnswer((_) async => Success([testTask]));
        return TasksBloc(taskRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const TasksLoadRequested()),
      expect: () => [
        const TasksLoading(),
        TasksLoaded(tasks: [testTask]),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits [Loading, Error] when TasksLoadRequested fails',
      build: () {
        when(() => mockRepo.getTasks()).thenAnswer(
          (_) async => const Failure(ServerFailure('Server error')),
        );
        return TasksBloc(taskRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const TasksLoadRequested()),
      expect: () => [
        const TasksLoading(),
        const TasksError(message: 'Server error'),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits [Loading, Loaded] when TaskCreateRequested succeeds',
      build: () {
        when(() => mockRepo.createTask(any()))
            .thenAnswer((_) async => Success(testTask));
        when(() => mockRepo.getTasks())
            .thenAnswer((_) async => Success([testTask]));
        return TasksBloc(taskRepository: mockRepo);
      },
      act: (bloc) => bloc.add(TaskCreateRequested(task: testTask)),
      expect: () => [
        const TasksLoading(),
        TasksLoaded(tasks: [testTask]),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits [Loading, Error] when TaskCreateRequested fails',
      build: () {
        when(() => mockRepo.createTask(any())).thenAnswer(
          (_) async => const Failure(ServerFailure('Create failed')),
        );
        return TasksBloc(taskRepository: mockRepo);
      },
      act: (bloc) => bloc.add(TaskCreateRequested(task: testTask)),
      expect: () => [
        const TasksLoading(),
        const TasksError(message: 'Create failed'),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits [Loading, Loaded] when TaskUpdateRequested succeeds',
      build: () {
        when(() => mockRepo.updateTask(any()))
            .thenAnswer((_) async => Success(testTask));
        when(() => mockRepo.getTasks())
            .thenAnswer((_) async => Success([testTask]));
        return TasksBloc(taskRepository: mockRepo);
      },
      act: (bloc) => bloc.add(TaskUpdateRequested(task: testTask)),
      expect: () => [
        const TasksLoading(),
        TasksLoaded(tasks: [testTask]),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits [Loading, Error] when TaskUpdateRequested fails',
      build: () {
        when(() => mockRepo.updateTask(any())).thenAnswer(
          (_) async => const Failure(ServerFailure('Update failed')),
        );
        return TasksBloc(taskRepository: mockRepo);
      },
      act: (bloc) => bloc.add(TaskUpdateRequested(task: testTask)),
      expect: () => [
        const TasksLoading(),
        const TasksError(message: 'Update failed'),
      ],
    );
  });
}
