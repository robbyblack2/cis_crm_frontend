import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/data/repositories/task_repository_impl.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements ActivityRemoteDataSource {}

class _FakeActivityModel extends Fake implements ActivityModel {}

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
  late _MockDataSource ds;
  late TaskRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(_FakeActivityModel());
  });

  setUp(() {
    ds = _MockDataSource();
    repo = TaskRepositoryImpl(remoteDataSource: ds);
  });

  group('getActivities', () {
    test('calls getActivities with no type filter and perPage=100', () async {
      when(() => ds.getActivities(perPage: 100))
          .thenAnswer((_) async => [_task]);

      final result = await repo.getActivities();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, hasLength(1));
      verify(() => ds.getActivities(perPage: 100)).called(1);
    });

    test('returns failure on ServerException', () async {
      when(() => ds.getActivities(perPage: 100))
          .thenThrow(const ServerException('fail'));

      final result = await repo.getActivities();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('getTasks', () {
    test('calls getActivities with activityType=task and perPage=100',
        () async {
      when(() => ds.getActivities(
            activityType: 'task',
            perPage: 100,
          )).thenAnswer((_) async => [_task]);

      final result = await repo.getTasks();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, hasLength(1));
      verify(() => ds.getActivities(activityType: 'task', perPage: 100))
          .called(1);
    });

    test('returns failure on ServerException', () async {
      when(() => ds.getActivities(
            activityType: 'task',
            perPage: 100,
          )).thenThrow(const ServerException('fail'));

      final result = await repo.getTasks();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('getTask', () {
    test('delegates to getActivity', () async {
      when(() => ds.getActivity('task-1'))
          .thenAnswer((_) async => _task);

      final result = await repo.getTask('task-1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.id, 'task-1');
    });
  });

  group('createTask', () {
    test('delegates to createActivity', () async {
      when(() => ds.createActivity(any()))
          .thenAnswer((_) async => _task);

      final result = await repo.createTask(_task);

      expect(result.isSuccess, isTrue);
      verify(() => ds.createActivity(_task)).called(1);
    });
  });

  group('updateTask', () {
    test('delegates to updateActivity', () async {
      when(() => ds.updateActivity(any()))
          .thenAnswer((_) async => _task);

      final result = await repo.updateTask(_task);

      expect(result.isSuccess, isTrue);
      verify(() => ds.updateActivity(_task)).called(1);
    });
  });

  group('deleteTask', () {
    test('delegates to deleteActivity', () async {
      when(() => ds.deleteActivity('task-1'))
          .thenAnswer((_) async {});

      final result = await repo.deleteTask('task-1');

      expect(result.isSuccess, isTrue);
      verify(() => ds.deleteActivity('task-1')).called(1);
    });

    test('returns NetworkFailure on NetworkException', () async {
      when(() => ds.deleteActivity('task-1'))
          .thenThrow(const NetworkException('offline'));

      final result = await repo.deleteTask('task-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });
}
