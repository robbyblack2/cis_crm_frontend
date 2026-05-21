import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_template_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EmailTemplateModel extends EmailTemplate {
  const EmailTemplateModel({
    required super.id,
    required super.name,
    required super.subjectTemplate,
    required super.bodyTemplate,
    required super.createdAt,
    required super.updatedAt,
    super.variables,
    super.createdBy,
  });

  factory EmailTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$EmailTemplateModelFromJson(json);

  Map<String, dynamic> toJson() => _$EmailTemplateModelToJson(this);
}
