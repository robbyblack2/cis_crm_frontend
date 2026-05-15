// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pipeline_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PipelineModel _$PipelineModelFromJson(Map<String, dynamic> json) =>
    PipelineModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      pipelineType: $enumDecode(_$PipelineTypeEnumMap, json['pipeline_type']),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PipelineModelToJson(PipelineModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sort_order': instance.sortOrder,
      'pipeline_type': _$PipelineTypeEnumMap[instance.pipelineType]!,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$PipelineTypeEnumMap = {
  PipelineType.sales: 'sales',
  PipelineType.support: 'support',
};
