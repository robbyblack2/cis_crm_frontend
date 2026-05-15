import 'package:cis_crm/features/email/domain/entities/email_message.dart';
import 'package:flutter/material.dart';

class EmailMessageTile extends StatelessWidget {
  const EmailMessageTile({required this.message, super.key});

  final EmailMessage message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(message.subject),
      subtitle: Text(message.senderEmail),
    );
  }
}
