import 'package:cis_crm/features/email/domain/entities/email_direction.dart';
import 'package:cis_crm/features/email/domain/entities/email_message.dart';

class EmailMessageModel extends EmailMessage {
  const EmailMessageModel({
    required super.id,
    required super.direction,
    required super.senderEmail,
    required super.recipientEmails,
    required super.subject,
    required super.body,
    required super.createsRecord,
    required super.timestamp,
    super.gmailMessageId,
    super.gmailThreadId,
    super.createdBy,
  });

  factory EmailMessageModel.fromJson(Map<String, dynamic> json) {
    return EmailMessageModel(
      id: json['id'] as String,
      direction: json['direction'] == 'inbound'
          ? EmailDirection.inbound
          : EmailDirection.outbound,
      senderEmail: json['from_address'] as String? ?? '',
      recipientEmails:
          (json['to_addresses'] as List<dynamic>?)?.cast<String>() ??
              const [],
      subject: json['subject'] as String? ?? '',
      body: json['body_html'] as String? ??
          json['body_text'] as String? ??
          '',
      createsRecord: json['creates_record'] as bool? ?? false,
      timestamp: DateTime.parse(json['created_at'] as String),
      gmailMessageId: json['gmail_message_id'] as String?,
      gmailThreadId: json['gmail_thread_id'] as String?,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction == EmailDirection.inbound
            ? 'inbound'
            : 'outbound',
        'from_address': senderEmail,
        'to_addresses': recipientEmails,
        'subject': subject,
        'body_html': body,
        'creates_record': createsRecord,
        'created_at': timestamp.toIso8601String(),
        'gmail_message_id': gmailMessageId,
        'gmail_thread_id': gmailThreadId,
        'created_by': createdBy,
      };
}
