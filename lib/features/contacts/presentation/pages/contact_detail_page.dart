import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:cis_crm/features/files/domain/repositories/file_repository.dart';
import 'package:cis_crm/features/files/presentation/widgets/file_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

String _fullName(Contact c) => '${c.firstName} ${c.lastName}'.trim();

String _formatTimestamp(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

String _initials(Contact c) {
  final first = c.firstName.isNotEmpty ? c.firstName[0] : '';
  final last = c.lastName.isNotEmpty ? c.lastName[0] : '';
  return '$first$last'.toUpperCase();
}

class ContactDetailPage extends StatefulWidget {
  const ContactDetailPage({
    required this.contact,
    super.key,
  });

  final Contact contact;

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  late Contact _contact;
  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _sourceCtrl;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _firstNameCtrl = TextEditingController(text: _contact.firstName);
    _lastNameCtrl = TextEditingController(text: _contact.lastName);
    _emailCtrl = TextEditingController(text: _contact.email);
    _phoneCtrl = TextEditingController(text: _contact.phone ?? '');
    _jobTitleCtrl = TextEditingController(text: _contact.jobTitle ?? '');
    _sourceCtrl = TextEditingController(text: _contact.source ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _jobTitleCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = Contact(
      id: _contact.id,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : null,
      jobTitle: _jobTitleCtrl.text.trim().isNotEmpty
          ? _jobTitleCtrl.text.trim()
          : null,
      source: _sourceCtrl.text.trim().isNotEmpty
          ? _sourceCtrl.text.trim()
          : null,
      status: _contact.status,
      tags: _contact.tags,
      ownerId: _contact.ownerId,
      companyId: _contact.companyId,
      version: _contact.version,
      createdAt: _contact.createdAt,
      updatedAt: DateTime.now(),
    );
    final result =
        await getIt<ContactRepository>().updateContact(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success(:final data):
        setState(() {
          _contact = data;
          _editing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact saved')),
        );
      case Failure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${error.message}')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fullName(_contact)),
        actions: [
          if (_editing) ...[
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
            const SizedBox(width: 8),
          ] else ...[
            if (_contact.email.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.email_outlined),
                tooltip: 'Send email',
                onPressed: () {
                  final uri = Uri(
                    scheme: 'mailto',
                    path: _contact.email,
                  );
                  launchUrl(uri);
                },
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => setState(() => _editing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outlined),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ContactHeader(contact: _contact),
            const SizedBox(height: 16),
            _editing
                ? _buildEditForm(context)
                : _ContactInfoCard(contact: _contact),
            if (_contact.tags.isNotEmpty && !_editing) ...[
              const SizedBox(height: 16),
              _TagsCard(tags: _contact.tags),
            ],
            const SizedBox(height: 16),
            _FilesSection(contactId: _contact.id),
            const SizedBox(height: 16),
            _ContactNotesSection(contactId: _contact.id),
            const SizedBox(height: 16),
            _ContactRecordsSection(contactId: _contact.id),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Contact',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 24),
            TextField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jobTitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sourceCtrl,
              decoration: const InputDecoration(
                labelText: 'Source',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete '
          '${_fullName(_contact)}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final result =
        await getIt<ContactRepository>().deleteContact(_contact.id);

    if (!context.mounted) return;

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted')),
        );
        Navigator.of(context).pop();
      case Failure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${error.message}')),
        );
    }
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: l10n.contactEmail,
              value: contact.email,
            ),
            if (contact.phone != null)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: l10n.contactPhone,
                value: contact.phone!,
              ),
            if (contact.source != null)
              _InfoRow(
                icon: Icons.source_outlined,
                label: l10n.contactSource,
                value: contact.source!,
              ),
            if (contact.companyId != null)
              _InfoRow(
                icon: Icons.business_outlined,
                label: l10n.contactCompany,
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
            Text(AppLocalizations.of(context)!.contactTags, style: theme.textTheme.titleMedium),
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
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = switch (status) {
      'active' => (l10n.contactStatusActive, Colors.green),
      'inactive' => (l10n.contactStatusInactive, Colors.grey),
      'lead' => (l10n.contactStatusLead, Colors.orange),
      'prospect' => (l10n.contactStatusProspect, Colors.blue),
      'customer' => (l10n.contactStatusCustomer, Colors.purple),
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

class _FilesSection extends StatelessWidget {
  const _FilesSection({required this.contactId});

  final String contactId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Files', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'File upload requires file_picker package',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<Result<List<FileAttachment>, AppFailure>>(
              future: getIt<FileRepository>().getFilesByParent(
                parentType: 'contact',
                parentId: contactId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Failed to load files.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                final result = snapshot.data;
                if (result == null) {
                  return const SizedBox.shrink();
                }

                return switch (result) {
                  Success(:final data) when data.isEmpty => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'No files attached to this contact.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Success(:final data) => Column(
                      children: data
                          .map(
                            (file) => FileTile(
                              file: file,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Download: ${file.filename}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  Failure(:final error) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Error: ${error.message}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact Notes ──────────────────────────────────────────────────────

class _ContactNotesSection extends StatefulWidget {
  const _ContactNotesSection({required this.contactId});
  final String contactId;

  @override
  State<_ContactNotesSection> createState() => _ContactNotesSectionState();
}

class _ContactNotesSectionState extends State<_ContactNotesSection> {
  List<Map<String, dynamic>>? _notes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notes = await getIt<ContactRemoteDataSource>()
          .getContactNotes(widget.contactId);
      if (mounted) setState(() { _notes = notes; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _notes = []; _loading = false; });
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_notes == null || _notes!.isEmpty)
              Text(
                'No notes yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...(_notes!).map(
                (n) => Card(
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['body'] as String? ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(
                            n['created_at'] as String?,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Contact Related Records ────────────────────────────────────────────

class _ContactRecordsSection extends StatefulWidget {
  const _ContactRecordsSection({required this.contactId});
  final String contactId;

  @override
  State<_ContactRecordsSection> createState() =>
      _ContactRecordsSectionState();
}

class _ContactRecordsSectionState extends State<_ContactRecordsSection> {
  List<Map<String, dynamic>>? _records;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await getIt<ContactRemoteDataSource>()
          .getContactRecords(widget.contactId);
      if (mounted) setState(() { _records = records; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _records = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Related Records',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_records == null || _records!.isEmpty)
              Text(
                'No related records',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...(_records!).map((r) {
                final data = r['data'] as Map<String, dynamic>? ?? {};
                final title = data['title'] as String? ?? 'Record';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.view_kanban_outlined),
                  title: Text(title),
                  subtitle: Text(r['source'] as String? ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                );
              }),
          ],
        ),
      ),
    );
  }
}
