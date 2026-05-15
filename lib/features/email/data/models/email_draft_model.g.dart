// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_draft_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailDraftModel _$EmailDraftModelFromJson(Map<String, dynamic> json) =>
    EmailDraftModel(
      id: json['id'] as String,
      recipientEmails: (json['recipient_emails'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      subject: json['subject'] as String,
      body: json['body'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$EmailDraftModelToJson(EmailDraftModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipient_emails': instance.recipientEmails,
      'subject': instance.subject,
      'body': instance.body,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
