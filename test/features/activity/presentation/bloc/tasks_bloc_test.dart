import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

class _FakeActivity extends Fake implements Activity {}

final _task = ActivityModel(
  id: 'task-1',
  activityType: ActivityType.task,
  title: 'Follow up',
  statusId: 's1',
  statusName: 'To Do',
  statusPhase: 'open',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late _MockTaskRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeActivity());
  });

  setUp(() {
    repository = _MockTaskRepository();
  });

  group('TasksBloc', () {
    blocTest<TasksBloc, TasksState>(
      'emits [loading, loaded] on successful load',
      build: () {
        when(() => repository.getActivities())
            .thenAnswer((_) async => Success([_task]));
        return TasksBloc(taskRepository: repository);
      },
      act: (bloc) => bloc.add(const TasksLoadRequested()),
      expect: () => [
        const TasksLoading(),
        isA<TasksLoaded>().having((s) => s.tasks.length, 'count', 1),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits [loading, error] on failed load',
      build: () {
        when(() => repository.getActivities()).thenAnswer(
          (_) async => const Failure(ServerFailure('fail')),
        );
        return TasksBloc(taskRepository: repository);
      },
      act: (bloc) => bloc.add(const TasksLoadRequested()),
      expect: () => [
        const TasksLoading(),
        const TasksError(message: 'fail'),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits [loading, loaded] on successful delete + reload',
      build: () {
        when(() => repository.deleteTask('task-1'))
            .thenAnswer((_) async => const Success(null));
        when(() => repository.getActivities())
            .thenAnswer((_) async => const Success(<Activity>[]));
        return TasksBloc(taskRepository: repository);
      },
      act: (bloc) => bloc.add(const TaskDeleted('task-1')),
      expect: () => [
        const TasksLoading(),
        isA<TasksLoaded>().having((s) => s.tasks, 'empty', isEmpty),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits error on failed delete',
      build: () {
        when(() => repository.deleteTask('task-1')).thenAnswer(
          (_) async => const Failure(NetworkFailure('offline')),
        );
        return TasksBloc(taskRepository: repository);
      },
      act: (bloc) => bloc.add(const TaskDeleted('task-1')),
      expect: () => [
        const TasksError(message: 'offline'),
      ],
    );
  });
}
