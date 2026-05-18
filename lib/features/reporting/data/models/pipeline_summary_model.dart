import 'package:cis_crm/features/reporting/domain/entities/pipeline_summary.dart';

class PipelineStageSummaryModel extends PipelineStageSummary {
  const PipelineStageSummaryModel({
    required super.stageId,
    required super.stageName,
    required super.count,
    required super.value,
  });

  factory PipelineStageSummaryModel.fromJson(Map<String, dynamic> json) {
    return PipelineStageSummaryModel(
      stageId: json['stage_id'] as String,
      stageName: json['stage_name'] as String,
      count: json['count'] as int,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'stage_id': stageId,
        'stage_name': stageName,
        'count': count,
        'value': value,
      };
}

class PipelineSummaryModel extends PipelineSummary {
  const PipelineSummaryModel({
    required super.pipelineId,
    required super.totalRecords,
    required super.totalValue,
    required super.byStage,
  });

  factory PipelineSummaryModel.fromJson(Map<String, dynamic> json) {
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return PipelineSummaryModel(
      pipelineId: data['pipeline_id'] as String,
      totalRecords: data['total_records'] as int,
      totalValue: (data['total_value'] as num).toDouble(),
      byStage: (data['by_stage'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(PipelineStageSummaryModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'pipeline_id': pipelineId,
        'total_records': totalRecords,
        'total_value': totalValue,
        'by_stage': byStage
            .cast<PipelineStageSummaryModel>()
            .map((s) => s.toJson())
            .toList(),
      };
}
