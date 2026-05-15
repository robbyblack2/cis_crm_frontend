// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StageModel _$StageModelFromJson(Map<String, dynamic> json) => StageModel(
      id: json['id'] as String,
      pipelineId: json['pipeline_id'] as String,
      name: json['name'] as String,
      position: (json['position'] as num).toInt(),
      stageType: $enumDecode(_$StageTypeEnumMap, json['stage_type']),
      color: json['color'] as String,
    );

Map<String, dynamic> _$StageModelToJson(StageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pipeline_id': instance.pipelineId,
      'name': instance.name,
      'position': instance.position,
      'stage_type': _$StageTypeEnumMap[instance.stageType]!,
      'color': instance.color,
    };

const _$StageTypeEnumMap = {
  StageType.normal: 'normal',
  StageType.won: 'won',
  StageType.lost: 'lost',
};
