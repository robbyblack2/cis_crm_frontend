import 'package:cis_crm/features/email/domain/entities/email_direction.dart';
import 'package:cis_crm/features/email/domain/entities/email_message.dart';
import 'package:flutter/material.dart';

class EmailMessageTile extends StatelessWidget {
  const EmailMessageTile({required this.message, this.onTap, super.key});

  final EmailMessage message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isInbound = message.direction == EmailDirection.inbound;

    return ListTile(
      leading: Icon(
        isInbound ? Icons.inbox_outlined : Icons.send_outlined,
        color: isInbound
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.tertiary,
      ),
      title: Text(
        message.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isInbound
            ? 'From: ${message.senderEmail}'
            : 'To: ${message.recipientEmails.join(', ')}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatTimestamp(message.timestamp),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }

  static String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }
}
