import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/reporting/data/datasources/report_remote_datasource.dart';
import 'package:cis_crm/features/reporting/domain/entities/pipeline_summary.dart';
import 'package:cis_crm/features/reporting/domain/entities/report.dart';
import 'package:cis_crm/features/reporting/domain/entities/report_result.dart';
import 'package:cis_crm/features/reporting/domain/repositories/report_repository.dart';
import 'package:dio/dio.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl({required ReportRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final ReportRemoteDataSource _dataSource;

  @override
  Future<Result<List<Report>, AppFailure>> getReports() async {
    try {
      final reports = await _dataSource.getReports();
      return Success(reports);
    } on DioException catch (e) {
      return Failure(_mapException(e));
    }
  }

  @override
  Future<Result<ReportResult, AppFailure>> runReport(String id) async {
    try {
      final result = await _dataSource.runReport(id);
      return Success(result);
    } on DioException catch (e) {
      return Failure(_mapException(e));
    }
  }

  @override
  Future<Result<Report, AppFailure>> createReport({
    required String name,
    String? description,
  }) async {
    try {
      final report = await _dataSource.createReport(
        name: name,
        description: description,
      );
      return Success(report);
    } on DioException catch (e) {
      return Failure(_mapException(e));
    }
  }

  @override
  Future<Result<String, AppFailure>> exportReport(String id) async {
    try {
      final csv = await _dataSource.exportReport(id);
      return Success(csv);
    } on DioException catch (e) {
      return Failure(_mapException(e));
    }
  }

  @override
  Future<Result<PipelineSummary, AppFailure>> getPipelineSummary(
    String pipelineId,
  ) async {
    try {
      final summary = await _dataSource.getPipelineSummary(pipelineId);
      return Success(summary);
    } on DioException catch (e) {
      return Failure(_mapException(e));
    }
  }

  AppFailure _mapException(DioException e) {
    final error = e.error;
    if (error is NetworkException) {
      return const NetworkFailure();
    }
    if (error is UnauthorizedException) {
      return UnauthorizedFailure(error.message);
    }
    if (error is ServerException) {
      return ServerFailure(error.message, statusCode: error.statusCode);
    }
    return const UnknownFailure();
  }
}
