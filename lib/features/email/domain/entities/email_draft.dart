import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class EmailDraft extends Equatable {
  const EmailDraft({
    required this.id,
    required this.recipientEmails,
    required this.subject,
    required this.body,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final List<String> recipientEmails;
  final String subject;
  final String body;
  final String createdBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        recipientEmails,
        subject,
        body,
        createdBy,
        createdAt,
      ];
}
