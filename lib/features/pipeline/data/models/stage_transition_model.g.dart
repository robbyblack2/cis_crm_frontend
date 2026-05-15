// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_transition_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StageTransitionModel _$StageTransitionModelFromJson(
        Map<String, dynamic> json) =>
    StageTransitionModel(
      id: json['id'] as String,
      recordId: json['record_id'] as String,
      fromStageId: json['from_stage_id'] as String,
      toStageId: json['to_stage_id'] as String,
      transitionedBy: json['transitioned_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$StageTransitionModelToJson(
        StageTransitionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'record_id': instance.recordId,
      'from_stage_id': instance.fromStageId,
      'to_stage_id': instance.toStageId,
      'transitioned_by': instance.transitionedBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
