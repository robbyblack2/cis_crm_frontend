import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:flutter/material.dart';

class EmailTemplateTile extends StatelessWidget {
  const EmailTemplateTile({required this.template, this.onTap, super.key});

  final EmailTemplate template;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(
        template.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        template.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
