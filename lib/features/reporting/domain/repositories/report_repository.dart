import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/reporting/domain/entities/report.dart';
import 'package:cis_crm/features/reporting/domain/entities/report_result.dart';

abstract interface class ReportRepository {
  Future<Result<List<Report>, AppFailure>> getReports();
  Future<Result<ReportResult, AppFailure>> runReport(String id);
  Future<Result<Report, AppFailure>> createReport({
    required String name,
    String? description,
  });
  Future<Result<String, AppFailure>> exportReport(String id);
}
