import 'package:cis_crm/features/email/domain/entities/email_draft.dart';

class EmailDraftModel extends EmailDraft {
  const EmailDraftModel({
    required super.id,
    required super.recipientEmails,
    required super.subject,
    required super.body,
    required super.createdBy,
    required super.createdAt,
  });

  factory EmailDraftModel.fromJson(Map<String, dynamic> json) {
    return EmailDraftModel(
      id: json['id'] as String,
      recipientEmails:
          (json['to_addresses'] as List<dynamic>?)?.cast<String>() ??
              const [],
      subject: json['subject'] as String? ?? '',
      body: json['body_html'] as String? ?? json['body'] as String? ?? '',
      createdBy: json['sent_by_user_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'to_addresses': recipientEmails,
        'subject': subject,
        'body_html': body,
        'sent_by_user_id': createdBy,
        'created_at': createdAt.toIso8601String(),
      };
}
