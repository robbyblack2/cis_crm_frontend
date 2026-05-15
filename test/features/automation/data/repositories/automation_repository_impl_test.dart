import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/automation/data/repositories/automation_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers.dart';

void main() {
  late MockAutomationRemoteDataSource dataSource;
  late AutomationRepositoryImpl repository;

  setUp(() {
    dataSource = MockAutomationRemoteDataSource();
    repository = AutomationRepositoryImpl(remoteDataSource: dataSource);
  });

  group('getRules', () {
    test('returns Success with rules when data source succeeds', () async {
      final rules = [createTestRuleModel()];
      when(() => dataSource.getRules()).thenAnswer((_) async => rules);

      final result = await repository.getRules();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(rules));
    });

    test('returns Failure with ServerFailure when ServerException is thrown',
        () async {
      when(() => dataSource.getRules())
          .thenThrow(const ServerException('Server error', statusCode: 500));

      final result = await repository.getRules();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('returns Failure with NetworkFailure when NetworkException is thrown',
        () async {
      when(() => dataSource.getRules()).thenThrow(const NetworkException());

      final result = await repository.getRules();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('getRule', () {
    test('returns Success with rule when data source succeeds', () async {
      final rule = createTestRuleModel();
      when(() => dataSource.getRule('rule-1')).thenAnswer((_) async => rule);

      final result = await repository.getRule('rule-1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(rule));
    });

    test('returns Failure when ServerException is thrown', () async {
      when(() => dataSource.getRule('rule-1'))
          .thenThrow(const ServerException('Not found', statusCode: 404));

      final result = await repository.getRule('rule-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('deleteRule', () {
    test('returns Success when data source succeeds', () async {
      when(() => dataSource.deleteRule('rule-1')).thenAnswer((_) async {});

      final result = await repository.deleteRule('rule-1');

      expect(result.isSuccess, isTrue);
    });

    test('returns Failure when ServerException is thrown', () async {
      when(() => dataSource.deleteRule('rule-1'))
          .thenThrow(const ServerException('Delete failed'));

      final result = await repository.deleteRule('rule-1');

      expect(result.isFailure, isTrue);
    });
  });

  group('toggleRule', () {
    test('returns Success with toggled rule when data source succeeds',
        () async {
      final rule = createTestRuleModel(isActive: false);
      when(() => dataSource.toggleRule('rule-1')).thenAnswer((_) async => rule);

      final result = await repository.toggleRule('rule-1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.isActive, isFalse);
    });
  });

  group('getExecutionLogs', () {
    test('returns Success with logs when data source succeeds', () async {
      final logs = [createTestLogModel()];
      when(() => dataSource.getExecutionLogs()).thenAnswer((_) async => logs);

      final result = await repository.getExecutionLogs();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(logs));
    });
  });
}
