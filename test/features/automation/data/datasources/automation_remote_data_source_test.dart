import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/automation/data/datasources/automation_remote_data_source.dart';
import 'package:cis_crm/features/automation/data/models/automation_rule_model.dart';
import 'package:cis_crm/features/automation/data/models/execution_log_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AutomationRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = AutomationRemoteDataSourceImpl(dio: dio);
  });

  final now = DateTime.utc(2026).toIso8601String();

  final ruleJson = <String, dynamic>{
    'id': 'rule-1',
    'name': 'Test Rule',
    'description': 'A test rule',
    'is_active': true,
    'trigger_type': 'on_create',
    'priority': 1,
    'created_by': 'user-1',
    'created_at': now,
    'updated_at': now,
  };

  final logJson = <String, dynamic>{
    'id': 'log-1',
    'rule_id': 'rule-1',
    'correlation_id': 'corr-1',
    'status': 'success',
    'error_detail': null,
    'created_at': now,
  };

  group('getRules', () {
    test('returns list of AutomationRuleModel on success', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{'data': [ruleJson]},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getRules();

      expect(result, isA<List<AutomationRuleModel>>());
      expect(result.length, 1);
      expect(result.first.id, 'rule-1');
    });

    test('throws ServerException on DioException', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
          message: 'Internal Server Error',
        ),
      );

      expect(
        () => dataSource.getRules(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getRule', () {
    test('returns AutomationRuleModel on success', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{'data': ruleJson},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getRule('rule-1');

      expect(result, isA<AutomationRuleModel>());
      expect(result.id, 'rule-1');
    });
  });

  group('createRule', () {
    test('returns AutomationRuleModel on success', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{'data': ruleJson},
          statusCode: 201,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.createRule(ruleJson);

      expect(result, isA<AutomationRuleModel>());
    });
  });

  group('deleteRule', () {
    test('completes successfully on 204', () async {
      when(() => dio.delete<void>(any())).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(),
        ),
      );

      await expectLater(dataSource.deleteRule('rule-1'), completes);
    });
  });

  group('toggleRule', () {
    test('returns toggled AutomationRuleModel on success', () async {
      when(() => dio.post<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'data': {...ruleJson, 'is_active': false},
          },
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.toggleRule('rule-1');

      expect(result.isActive, isFalse);
    });
  });

  group('dryRunRule', () {
    test('returns ExecutionLogModel on success', () async {
      when(() => dio.post<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{'data': logJson},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.dryRunRule('rule-1');

      expect(result, isA<ExecutionLogModel>());
      expect(result.ruleId, 'rule-1');
    });
  });

  group('getExecutionLogs', () {
    test('returns list of ExecutionLogModel on success', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{'data': [logJson]},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getExecutionLogs();

      expect(result, isA<List<ExecutionLogModel>>());
      expect(result.length, 1);
    });
  });
}
