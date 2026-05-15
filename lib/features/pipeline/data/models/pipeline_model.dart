import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pipeline_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PipelineModel extends Pipeline {
  const PipelineModel({
    required super.id,
    required super.name,
    required super.sortOrder,
    required super.pipelineType,
    required super.isActive,
    required super.createdAt,
  });

  factory PipelineModel.fromJson(Map<String, dynamic> json) =>
      _$PipelineModelFromJson(json);

  Map<String, dynamic> toJson() => _$PipelineModelToJson(this);
}
