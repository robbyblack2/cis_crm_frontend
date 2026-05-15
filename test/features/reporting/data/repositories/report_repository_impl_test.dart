import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/reporting/data/datasources/report_remote_datasource.dart';
import 'package:cis_crm/features/reporting/data/models/report_model.dart';
import 'package:cis_crm/features/reporting/data/models/report_result_model.dart';
import 'package:cis_crm/features/reporting/data/repositories/report_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRemoteDataSource extends Mock
    implements ReportRemoteDataSource {}

void main() {
  late MockReportRemoteDataSource mockDataSource;
  late ReportRepositoryImpl repository;

  final tNow = DateTime(2026);
  final tReportModel = ReportModel(
    id: '1',
    name: 'Sales Report',
    description: 'Monthly sales',
    createdBy: 'user-1',
    createdAt: tNow,
    updatedAt: tNow,
  );
  const tResultModel = ReportResultModel(
    columns: ['name', 'total'],
    rows: [
      {'name': 'Alice', 'total': 100},
    ],
  );

  setUp(() {
    mockDataSource = MockReportRemoteDataSource();
    repository = ReportRepositoryImpl(dataSource: mockDataSource);
  });

  DioException dioError(AppException appException) => DioException(
        requestOptions: RequestOptions(),
        error: appException,
      );

  group('getReports', () {
    test('returns Success with reports on success', () async {
      when(() => mockDataSource.getReports())
          .thenAnswer((_) async => [tReportModel]);

      final result = await repository.getReports();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, [tReportModel]);
    });

    test('returns Failure(NetworkFailure) on NetworkException', () async {
      when(() => mockDataSource.getReports())
          .thenThrow(dioError(const NetworkException()));

      final result = await repository.getReports();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('returns Failure(ServerFailure) on ServerException', () async {
      when(() => mockDataSource.getReports()).thenThrow(
        dioError(const ServerException('fail', statusCode: 500)),
      );

      final result = await repository.getReports();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'returns Failure(UnauthorizedFailure) on UnauthorizedException',
      () async {
        when(() => mockDataSource.getReports())
            .thenThrow(dioError(const UnauthorizedException()));

        final result = await repository.getReports();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      },
    );
  });

  group('runReport', () {
    test('returns Success with ReportResult on success', () async {
      when(() => mockDataSource.runReport('1'))
          .thenAnswer((_) async => tResultModel);

      final result = await repository.runReport('1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, tResultModel);
    });

    test('returns Failure on error', () async {
      when(() => mockDataSource.runReport('1'))
          .thenThrow(dioError(const ServerException('not found')));

      final result = await repository.runReport('1');

      expect(result.isFailure, isTrue);
    });
  });

  group('createReport', () {
    test('returns Success with created report', () async {
      when(
        () => mockDataSource.createReport(
          name: 'New Report',
          description: 'desc',
        ),
      ).thenAnswer((_) async => tReportModel);

      final result = await repository.createReport(
        name: 'New Report',
        description: 'desc',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, tReportModel);
    });
  });

  group('exportReport', () {
    test('returns Success with CSV string', () async {
      when(() => mockDataSource.exportReport('1'))
          .thenAnswer((_) async => 'name,total\nAlice,100');

      final result = await repository.exportReport('1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 'name,total\nAlice,100');
    });
  });
}
