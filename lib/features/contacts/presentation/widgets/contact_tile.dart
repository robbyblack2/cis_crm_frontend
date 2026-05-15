import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:flutter/material.dart';

class ContactTile extends StatelessWidget {
  const ContactTile({required this.contact, this.onTap, super.key});

  final Contact contact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          '${contact.firstName[0]}${contact.lastName[0]}',
        ),
      ),
      title: Text('${contact.firstName} ${contact.lastName}'),
      subtitle: Text(contact.email),
      trailing: Text(contact.status),
      onTap: onTap,
    );
  }
}
