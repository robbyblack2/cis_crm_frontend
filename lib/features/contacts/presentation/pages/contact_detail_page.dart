import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/responsive/breakpoints.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:flutter/material.dart';

String _fullName(Contact c) => '${c.firstName} ${c.lastName}'.trim();

String _initials(Contact c) {
  final first = c.firstName.isNotEmpty ? c.firstName[0] : '';
  final last = c.lastName.isNotEmpty ? c.lastName[0] : '';
  return '$first$last'.toUpperCase();
}

class ContactDetailPage extends StatelessWidget {
  const ContactDetailPage({
    required this.contact,
    super.key,
  });

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fullName(contact)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit contact',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            tooltip: 'Delete contact',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final windowSize = windowSizeFor(constraints.maxWidth);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: switch (windowSize) {
              WindowSize.compact => _CompactLayout(contact: contact),
              WindowSize.medium ||
              WindowSize.expanded =>
                _WideLayout(contact: contact),
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text(
          'Are you sure you want to delete ${_fullName(contact)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final result = await getIt<ContactRepository>()
                  .deleteContact(contact.id);
              if (!context.mounted) return;
              switch (result) {
                case Success():
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact deleted')),
                  );
                  Navigator.of(context).pop();
                case Failure(:final error):
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: ${error.message}'),
                    ),
                  );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ContactHeader extends StatelessWidget {
  const _ContactHeader({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                _initials(contact),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _fullName(contact),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (contact.jobTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                contact.jobTitle!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            _StatusChip(status: contact.status),
          ],
        ),
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: contact.email,
            ),
            if (contact.phone != null)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: contact.phone!,
              ),
            if (contact.source != null)
              _InfoRow(
                icon: Icons.source_outlined,
                label: 'Source',
                value: contact.source!,
              ),
            if (contact.companyId != null)
              _InfoRow(
                icon: Icons.business_outlined,
                label: 'Company',
                value: contact.companyId!,
              ),
          ],
        ),
      ),
    );
  }
}

class _TagsCard extends StatelessWidget {
  const _TagsCard({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tags', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(label, style: theme.textTheme.labelMedium),
      subtitle: Text(value, style: theme.textTheme.bodyLarge),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Active', Colors.green),
      'inactive' => ('Inactive', Colors.grey),
      'lead' => ('Lead', Colors.orange),
      'prospect' => ('Prospect', Colors.blue),
      'customer' => ('Customer', Colors.purple),
      _ => (status, Colors.grey),
    };

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color.shade700),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContactHeader(contact: contact),
        const SizedBox(height: 16),
        _ContactInfoCard(contact: contact),
        if (contact.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _TagsCard(tags: contact.tags),
        ],
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ContactHeader(contact: contact),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContactInfoCard(contact: contact),
              if (contact.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TagsCard(tags: contact.tags),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
