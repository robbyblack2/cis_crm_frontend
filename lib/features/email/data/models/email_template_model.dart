import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_template_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EmailTemplateModel extends EmailTemplate {
  const EmailTemplateModel({
    required super.id,
    required super.name,
    required super.subject,
    required super.body,
    required super.createdAt,
    required super.updatedAt,
  });

  factory EmailTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$EmailTemplateModelFromJson(json);

  Map<String, dynamic> toJson() => _$EmailTemplateModelToJson(this);
}
