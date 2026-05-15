import 'package:cis_crm/features/activity/domain/entities/timeline_entry.dart';
import 'package:json_annotation/json_annotation.dart';

part 'timeline_entry_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TimelineEntryModel extends TimelineEntry {
  const TimelineEntryModel({
    required super.id,
    required super.entityType,
    required super.entityId,
    required super.eventType,
    required super.actorType,
    required super.actorId,
    required super.summary,
    required super.createdAt,
  });

  factory TimelineEntryModel.fromJson(Map<String, dynamic> json) =>
      _$TimelineEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$TimelineEntryModelToJson(this);
}
