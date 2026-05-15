import 'package:cis_crm/features/reporting/data/datasources/report_remote_datasource.dart';
import 'package:cis_crm/features/reporting/data/models/report_model.dart';
import 'package:cis_crm/features/reporting/data/models/report_result_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ReportRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = ReportRemoteDataSourceImpl(dio: mockDio);
  });

  final tNow = DateTime(2026).toIso8601String();
  final tReportJson = {
    'id': '1',
    'name': 'Sales Report',
    'description': 'Monthly sales',
    'created_by': 'user-1',
    'created_at': tNow,
    'updated_at': tNow,
  };
  const tResultJson = {
    'columns': ['name', 'total'],
    'rows': [
      {'name': 'Alice', 'total': 100},
    ],
  };

  group('getReports', () {
    test('returns list of ReportModel from GET /api/reports', () async {
      when(() => mockDio.get<List<dynamic>>('/api/reports')).thenAnswer(
        (_) async => Response(
          data: [tReportJson],
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getReports();

      expect(result, isA<List<ReportModel>>());
      expect(result.length, 1);
      expect(result.first.id, '1');
    });
  });

  group('runReport', () {
    test('returns ReportResultModel from GET /api/reports/:id', () async {
      when(() => mockDio.get<Map<String, dynamic>>('/api/reports/1'))
          .thenAnswer(
        (_) async => Response(
          data: tResultJson,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.runReport('1');

      expect(result, isA<ReportResultModel>());
      expect(result.columns, ['name', 'total']);
    });
  });

  group('createReport', () {
    test('returns ReportModel from POST /api/reports', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/reports',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tReportJson,
          statusCode: 201,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.createReport(
        name: 'Sales Report',
        description: 'Monthly sales',
      );

      expect(result, isA<ReportModel>());
      expect(result.name, 'Sales Report');
    });
  });

  group('exportReport', () {
    test('returns CSV string from GET /api/reports/:id/export', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>('/api/reports/1/export'),
      ).thenAnswer(
        (_) async => Response(
          data: {'csv': 'name,total\nAlice,100'},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.exportReport('1');

      expect(result, 'name,total\nAlice,100');
    });
  });
}
