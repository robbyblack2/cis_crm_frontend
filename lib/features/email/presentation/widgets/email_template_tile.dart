import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:flutter/material.dart';

class EmailTemplateTile extends StatelessWidget {
  const EmailTemplateTile({
    required this.template,
    this.onTap,
    this.onDelete,
    super.key,
  });

  final EmailTemplate template;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(
        template.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        template.subjectTemplate,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit',
            onPressed: onTap,
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
