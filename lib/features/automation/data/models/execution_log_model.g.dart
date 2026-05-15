// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExecutionLogModel _$ExecutionLogModelFromJson(Map<String, dynamic> json) =>
    ExecutionLogModel(
      id: json['id'] as String,
      ruleId: json['rule_id'] as String,
      correlationId: json['correlation_id'] as String,
      status: $enumDecode(_$ExecutionStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      errorDetail: json['error_detail'] as String?,
    );

Map<String, dynamic> _$ExecutionLogModelToJson(ExecutionLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rule_id': instance.ruleId,
      'correlation_id': instance.correlationId,
      'status': _$ExecutionStatusEnumMap[instance.status]!,
      'error_detail': instance.errorDetail,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ExecutionStatusEnumMap = {
  ExecutionStatus.success: 'success',
  ExecutionStatus.partialFailure: 'partialFailure',
  ExecutionStatus.failed: 'failed',
  ExecutionStatus.dryRun: 'dryRun',
};
