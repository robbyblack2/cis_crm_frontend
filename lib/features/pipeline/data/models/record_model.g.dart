// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordModel _$RecordModelFromJson(Map<String, dynamic> json) => RecordModel(
      id: json['id'] as String,
      pipelineId: json['pipeline_id'] as String,
      stageId: json['stage_id'] as String,
      title: json['title'] as String,
      source: $enumDecode(_$RecordSourceEnumMap, json['source']),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      contactId: json['contact_id'] as String?,
      companyId: json['company_id'] as String?,
      ownerId: json['owner_id'] as String?,
    );

Map<String, dynamic> _$RecordModelToJson(RecordModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pipeline_id': instance.pipelineId,
      'stage_id': instance.stageId,
      'contact_id': instance.contactId,
      'company_id': instance.companyId,
      'owner_id': instance.ownerId,
      'title': instance.title,
      'source': _$RecordSourceEnumMap[instance.source]!,
      'tags': instance.tags,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$RecordSourceEnumMap = {
  RecordSource.manual: 'manual',
  RecordSource.email: 'email',
  RecordSource.syncRule: 'syncRule',
  RecordSource.automation: 'automation',
};
