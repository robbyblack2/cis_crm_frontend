import 'package:cis_crm/features/pipeline/domain/entities/stage_transition.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stage_transition_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StageTransitionModel extends StageTransition {
  const StageTransitionModel({
    required super.id,
    required super.recordId,
    required super.fromStageId,
    required super.toStageId,
    required super.transitionedBy,
    required super.createdAt,
  });

  factory StageTransitionModel.fromJson(Map<String, dynamic> json) =>
      _$StageTransitionModelFromJson(json);

  Map<String, dynamic> toJson() => _$StageTransitionModelToJson(this);
}
