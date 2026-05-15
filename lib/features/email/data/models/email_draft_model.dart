import 'package:cis_crm/features/email/domain/entities/email_draft.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_draft_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EmailDraftModel extends EmailDraft {
  const EmailDraftModel({
    required super.id,
    required super.recipientEmails,
    required super.subject,
    required super.body,
    required super.createdBy,
    required super.createdAt,
  });

  factory EmailDraftModel.fromJson(Map<String, dynamic> json) =>
      _$EmailDraftModelFromJson(json);

  Map<String, dynamic> toJson() => _$EmailDraftModelToJson(this);
}
