import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/reporting/domain/entities/pipeline_summary.dart';
import 'package:cis_crm/features/reporting/domain/entities/report.dart';
import 'package:cis_crm/features/reporting/domain/entities/report_result.dart';
import 'package:cis_crm/features/reporting/domain/repositories/report_repository.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_cubit.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late MockReportRepository mockRepository;
  late ReportsCubit cubit;

  final tNow = DateTime(2026);
  final tReport = Report(
    id: '1',
    name: 'Sales Report',
    description: 'Monthly sales',
    createdBy: 'user-1',
    createdAt: tNow,
    updatedAt: tNow,
  );
  final tReports = [tReport];
  const tReportResult = ReportResult(
    columns: ['name', 'total'],
    rows: [
      {'name': 'Alice', 'total': 100},
    ],
  );

  setUp(() {
    mockRepository = MockReportRepository();
    cubit = ReportsCubit(repository: mockRepository);
  });

  tearDown(() => cubit.close());

  test('initial state is ReportsInitial', () {
    expect(cubit.state, const ReportsInitial());
  });

  group('loadReports', () {
    blocTest<ReportsCubit, ReportsState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => mockRepository.getReports())
            .thenAnswer((_) async => Success(tReports));
        return cubit;
      },
      act: (c) => c.loadReports(),
      expect: () => [
        const ReportsLoading(),
        ReportsLoaded(tReports),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getReports()).thenAnswer(
          (_) async => const Failure(ServerFailure('Server error')),
        );
        return cubit;
      },
      act: (c) => c.loadReports(),
      expect: () => [
        const ReportsLoading(),
        const ReportsError('Server error'),
      ],
    );
  });

  group('runReport', () {
    blocTest<ReportsCubit, ReportsState>(
      'emits [ReportRunning, ReportLoaded] on success',
      build: () {
        when(() => mockRepository.runReport('1'))
            .thenAnswer((_) async => const Success(tReportResult));
        return cubit;
      },
      act: (c) => c.runReport('1'),
      expect: () => [
        const ReportRunning(),
        const ReportLoaded(tReportResult),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits [ReportRunning, Error] on failure',
      build: () {
        when(() => mockRepository.runReport('1')).thenAnswer(
          (_) async => const Failure(ServerFailure('Not found')),
        );
        return cubit;
      },
      act: (c) => c.runReport('1'),
      expect: () => [
        const ReportRunning(),
        const ReportsError('Not found'),
      ],
    );
  });

  group('loadPipelineSummary', () {
    const tPipelineSummary = PipelineSummary(
      pipelineId: 'p1',
      totalRecords: 45,
      totalValue: 2250000,
      byStage: [
        PipelineStageSummary(
          stageId: 's1',
          stageName: 'Qualified',
          count: 10,
          value: 500000,
        ),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits [PipelineSummaryLoading, PipelineSummaryLoaded] on success',
      build: () {
        when(() => mockRepository.getPipelineSummary('p1'))
            .thenAnswer((_) async => const Success(tPipelineSummary));
        return cubit;
      },
      act: (c) => c.loadPipelineSummary('p1'),
      expect: () => [
        const PipelineSummaryLoading(),
        const PipelineSummaryLoaded(tPipelineSummary),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits [PipelineSummaryLoading, Error] on failure',
      build: () {
        when(() => mockRepository.getPipelineSummary('p1')).thenAnswer(
          (_) async => const Failure(ServerFailure('Pipeline not found')),
        );
        return cubit;
      },
      act: (c) => c.loadPipelineSummary('p1'),
      expect: () => [
        const PipelineSummaryLoading(),
        const ReportsError('Pipeline not found'),
      ],
    );
  });
}
