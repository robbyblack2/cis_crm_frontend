import 'package:cis_crm/features/reporting/data/models/pipeline_summary_model.dart';
import 'package:cis_crm/features/reporting/data/models/report_model.dart';
import 'package:cis_crm/features/reporting/data/models/report_result_model.dart';
import 'package:dio/dio.dart';

abstract interface class ReportRemoteDataSource {
  Future<List<ReportModel>> getReports();
  Future<ReportResultModel> runReport(String id);
  Future<ReportModel> createReport({
    required String name,
    String? description,
  });
  Future<String> exportReport(String id);
  Future<PipelineSummaryModel> getPipelineSummary(String pipelineId);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  const ReportRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<ReportModel>> getReports() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/reports');
    final list = response.data?['data'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .cast<Map<String, dynamic>>()
        .map(ReportModel.fromJson)
        .toList();
  }

  @override
  Future<ReportResultModel> runReport(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/reports/$id');
    return ReportResultModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ReportModel> createReport({
    required String name,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/reports',
      data: {'name': name, 'description': description},
    );
    return ReportModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<String> exportReport(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/reports/$id/export');
    final data = response.data!['data'] as Map<String, dynamic>;
    return data['csv'] as String;
  }

  @override
  Future<PipelineSummaryModel> getPipelineSummary(String pipelineId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/reports/pipeline-summary/$pipelineId',
    );
    return PipelineSummaryModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}
