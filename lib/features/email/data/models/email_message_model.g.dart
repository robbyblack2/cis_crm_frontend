// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailMessageModel _$EmailMessageModelFromJson(Map<String, dynamic> json) =>
    EmailMessageModel(
      id: json['id'] as String,
      direction: $enumDecode(_$EmailDirectionEnumMap, json['direction']),
      senderEmail: json['sender_email'] as String,
      recipientEmails: (json['recipient_emails'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      subject: json['subject'] as String,
      body: json['body'] as String,
      createsRecord: json['creates_record'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      gmailMessageId: json['gmail_message_id'] as String?,
      gmailThreadId: json['gmail_thread_id'] as String?,
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$EmailMessageModelToJson(EmailMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gmail_message_id': instance.gmailMessageId,
      'gmail_thread_id': instance.gmailThreadId,
      'direction': _$EmailDirectionEnumMap[instance.direction]!,
      'sender_email': instance.senderEmail,
      'recipient_emails': instance.recipientEmails,
      'subject': instance.subject,
      'body': instance.body,
      'creates_record': instance.createsRecord,
      'timestamp': instance.timestamp.toIso8601String(),
      'created_by': instance.createdBy,
    };

const _$EmailDirectionEnumMap = {
  EmailDirection.inbound: 'inbound',
  EmailDirection.outbound: 'outbound',
};
