import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'record_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
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

  factory RecordModel.fromJson(Map<String, dynamic> json) =>
      _$RecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$RecordModelToJson(this);
}
