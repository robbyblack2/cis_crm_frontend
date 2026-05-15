import 'package:cis_crm/features/email/domain/entities/email_direction.dart';
import 'package:cis_crm/features/email/domain/entities/email_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_message_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
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

  factory EmailMessageModel.fromJson(Map<String, dynamic> json) =>
      _$EmailMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$EmailMessageModelToJson(this);
}
