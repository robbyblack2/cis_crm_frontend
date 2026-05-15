import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stage_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StageModel extends Stage {
  const StageModel({
    required super.id,
    required super.pipelineId,
    required super.name,
    required super.position,
    required super.stageType,
    required super.color,
  });

  factory StageModel.fromJson(Map<String, dynamic> json) =>
      _$StageModelFromJson(json);

  Map<String, dynamic> toJson() => _$StageModelToJson(this);
}
