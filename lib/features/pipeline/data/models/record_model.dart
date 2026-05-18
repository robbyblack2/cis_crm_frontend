import 'package:cis_crm/features/pipeline/domain/entities/record.dart';

const _sourceMap = {
  'manual': RecordSource.manual,
  'email': RecordSource.email,
  'sync_rule': RecordSource.syncRule,
  'automation': RecordSource.automation,
};

const _sourceToString = {
  RecordSource.manual: 'manual',
  RecordSource.email: 'email',
  RecordSource.syncRule: 'sync_rule',
  RecordSource.automation: 'automation',
};

class RecordModel extends PipelineRecord {
  const RecordModel({
    required super.id,
    required super.pipelineId,
    required super.stageId,
    required super.title,
    required super.source,
    required super.tags,
    required super.createdAt,
    required super.updatedAt,
    super.contactId,
    super.companyId,
    super.ownerId,
  });

  factory RecordModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return RecordModel(
      id: json['id'] as String,
      pipelineId: json['pipeline_id'] as String,
      stageId: json['stage_id'] as String,
      contactId: json['contact_id'] as String?,
      companyId: json['company_id'] as String?,
      ownerId: json['owner_id'] as String?,
      title: data['title'] as String? ?? '',
      source: _sourceMap[json['source'] as String?] ?? RecordSource.manual,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pipeline_id': pipelineId,
        'stage_id': stageId,
        'contact_id': contactId,
        'company_id': companyId,
        'owner_id': ownerId,
        'source': _sourceToString[source],
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'data': {
          'title': title,
        },
      };
}
