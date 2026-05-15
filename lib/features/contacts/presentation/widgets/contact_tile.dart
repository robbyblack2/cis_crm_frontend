import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:flutter/material.dart';

class ContactTile extends StatelessWidget {
  const ContactTile({
    required this.contact,
    this.onTap,
    super.key,
  });

  final Contact contact;
  final VoidCallback? onTap;

  String get _fullName => '${contact.firstName} ${contact.lastName}'.trim();

  String get _initials {
    final first = contact.firstName.isNotEmpty ? contact.firstName[0] : '';
    final last = contact.lastName.isNotEmpty ? contact.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        child: Text(
          _initials,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(_fullName),
      subtitle: Text(contact.email),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
