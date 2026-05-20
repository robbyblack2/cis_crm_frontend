import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'crm_task_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CrmTaskModel extends CrmTask {
  const CrmTaskModel({
    required super.id,
    required super.title,
    required super.status,
    required super.priority,
    super.parentType,
    super.parentId,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.assigneeId,
    super.dueDate,
    super.completedAt,
    super.version,
  });

  factory CrmTaskModel.fromJson(Map<String, dynamic> json) =>
      _$CrmTaskModelFromJson(json);

  factory CrmTaskModel.fromEntity(CrmTask task) => CrmTaskModel(
        id: task.id,
        title: task.title,
        status: task.status,
        priority: task.priority,
        parentType: task.parentType,
        parentId: task.parentId,
        createdBy: task.createdBy,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        description: task.description,
        assigneeId: task.assigneeId,
        dueDate: task.dueDate,
        completedAt: task.completedAt,
        version: task.version,
      );

  Map<String, dynamic> toJson() => _$CrmTaskModelToJson(this);
}
