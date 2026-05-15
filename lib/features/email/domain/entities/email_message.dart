import 'package:cis_crm/features/email/domain/entities/email_direction.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class EmailMessage extends Equatable {
  const EmailMessage({
    required this.id,
    required this.direction,
    required this.senderEmail,
    required this.recipientEmails,
    required this.subject,
    required this.body,
    required this.createsRecord,
    required this.timestamp,
    this.gmailMessageId,
    this.gmailThreadId,
    this.createdBy,
  });

  final String id;
  final String? gmailMessageId;
  final String? gmailThreadId;
  final EmailDirection direction;
  final String senderEmail;
  final List<String> recipientEmails;
  final String subject;
  final String body;
  final bool createsRecord;
  final DateTime timestamp;
  final String? createdBy;

  @override
  List<Object?> get props => [
        id,
        gmailMessageId,
        gmailThreadId,
        direction,
        senderEmail,
        recipientEmails,
        subject,
        body,
        createsRecord,
        timestamp,
        createdBy,
      ];
}
