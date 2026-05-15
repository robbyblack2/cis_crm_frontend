// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailTemplateModel _$EmailTemplateModelFromJson(Map<String, dynamic> json) =>
    EmailTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EmailTemplateModelToJson(EmailTemplateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'subject': instance.subject,
      'body': instance.body,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
