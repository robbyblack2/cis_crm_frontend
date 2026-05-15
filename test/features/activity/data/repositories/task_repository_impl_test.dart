import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:cis_crm/features/activity/data/models/crm_task_model.dart';
import 'package:cis_crm/features/activity/data/repositories/task_repository_impl.dart';
import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteDataSource extends Mock implements ActivityRemoteDataSource {}

class FakeCrmTaskModel extends Fake implements CrmTaskModel {}

void main() {
  late MockRemoteDataSource mockDataSource;
  late TaskRepositoryImpl repo;

  final now = DateTime(2024);
  final testModel = CrmTaskModel(
    id: '1',
    title: 'Test',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    parentType: 'contact',
    parentId: 'c1',
    createdBy: 'user1',
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(FakeCrmTaskModel());
  });

  setUp(() {
    mockDataSource = MockRemoteDataSource();
    repo = TaskRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('getTasks', () {
    test('returns Success with tasks when datasource succeeds', () async {
      when(() => mockDataSource.getTasks())
          .thenAnswer((_) async => [testModel]);
      final result = await repo.getTasks();
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, [testModel]);
    });

    test('returns Failure(ServerFailure) when ServerException thrown',
        () async {
      when(() => mockDataSource.getTasks())
          .thenThrow(const ServerException('fail', statusCode: 500));
      final result = await repo.getTasks();
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('returns Failure(NetworkFailure) when NetworkException thrown',
        () async {
      when(() => mockDataSource.getTasks()).thenThrow(const NetworkException());
      final result = await repo.getTasks();
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('createTask', () {
    test('returns Success when datasource succeeds', () async {
      when(() => mockDataSource.createTask(any()))
          .thenAnswer((_) async => testModel);
      final result = await repo.createTask(testModel);
      expect(result.isSuccess, isTrue);
    });

    test('returns Failure when datasource throws', () async {
      when(() => mockDataSource.createTask(any()))
          .thenThrow(const ServerException('fail'));
      final result = await repo.createTask(testModel);
      expect(result.isFailure, isTrue);
    });
  });

  group('updateTask', () {
    test('returns Success when datasource succeeds', () async {
      when(() => mockDataSource.updateTask(any()))
          .thenAnswer((_) async => testModel);
      final result = await repo.updateTask(testModel);
      expect(result.isSuccess, isTrue);
    });
  });

  group('deleteTask', () {
    test('returns Success when datasource succeeds', () async {
      when(() => mockDataSource.deleteTask(any())).thenAnswer((_) async {});
      final result = await repo.deleteTask('1');
      expect(result.isSuccess, isTrue);
    });

    test('returns Failure when datasource throws', () async {
      when(() => mockDataSource.deleteTask(any()))
          .thenThrow(const ServerException('fail'));
      final result = await repo.deleteTask('1');
      expect(result.isFailure, isTrue);
    });
  });
}
