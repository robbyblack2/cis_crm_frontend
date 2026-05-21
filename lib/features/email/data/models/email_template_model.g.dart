// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailTemplateModel _$EmailTemplateModelFromJson(Map<String, dynamic> json) =>
    EmailTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      subjectTemplate: json['subject_template'] as String,
      bodyTemplate: json['body_template'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      variables: json['variables'],
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$EmailTemplateModelToJson(EmailTemplateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'subject_template': instance.subjectTemplate,
      'body_template': instance.bodyTemplate,
      'variables': instance.variables,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
