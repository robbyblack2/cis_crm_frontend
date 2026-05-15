import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:flutter/material.dart';

class ContactDetailPage extends StatelessWidget {
  const ContactDetailPage({required this.contact, super.key});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${contact.firstName} ${contact.lastName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${contact.firstName} ${contact.lastName}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(contact.email),
            if (contact.phone != null) Text(contact.phone!),
            if (contact.jobTitle != null) Text(contact.jobTitle!),
          ],
        ),
      ),
    );
  }
}
