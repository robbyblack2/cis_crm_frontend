import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:flutter/material.dart';

class EmailTemplateTile extends StatelessWidget {
  const EmailTemplateTile({required this.template, super.key});

  final EmailTemplate template;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(template.name),
      subtitle: Text(template.subject),
    );
  }
}
