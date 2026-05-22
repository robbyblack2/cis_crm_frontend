import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/utils/html_utils.dart';
import 'package:cis_crm/core/widgets/crm_tag_chip.dart';
import 'package:dio/dio.dart';
import 'package:cis_crm/core/widgets/html_email_view.dart';
import 'package:cis_crm/core/widgets/activities_section.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/contacts/presentation/pages/company_detail_page.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:cis_crm/features/files/domain/repositories/file_repository.dart';
import 'package:cis_crm/features/files/presentation/widgets/file_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cis_crm/features/email/presentation/pages/email_compose_page.dart';

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

class _ContactDetailPageState extends State<ContactDetailPage>
    with TickerProviderStateMixin {
  late Contact _contact;
  bool _editing = false;
  bool _saving = false;
  late final TabController _tabController;

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
    _tabController = TabController(length: 4, vsync: this);
    _firstNameCtrl = TextEditingController(text: _contact.firstName);
    _lastNameCtrl = TextEditingController(text: _contact.lastName);
    _emailCtrl = TextEditingController(text: _contact.email);
    _phoneCtrl = TextEditingController(text: _contact.phone ?? '');
    _jobTitleCtrl = TextEditingController(text: _contact.jobTitle ?? '');
    _sourceCtrl = TextEditingController(text: _contact.source ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EmailComposePage(
                        initialTo: _contact.email,
                        contactId: _contact.id,
                      ),
                    ),
                  );
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
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Overview'),
              Tab(icon: Icon(Icons.email_outlined, size: 18), text: 'Email'),
              Tab(icon: Icon(Icons.history_outlined, size: 18), text: 'Activity'),
              Tab(icon: Icon(Icons.link_outlined, size: 18), text: 'Related'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Overview tab ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ContactHeader(contact: _contact),
                      const SizedBox(height: 16),
                      _editing
                          ? _buildEditForm(context)
                          : _ContactInfoCard(
                              contact: _contact,
                              onFieldSaved: (updated) {
                                setState(() => _contact = updated);
                              },
                            ),
                      if (!_editing) ...[
                        const SizedBox(height: 16),
                        _TagsCard(
                          tags: _contact.tags,
                          contactId: _contact.id,
                          contact: _contact,
                          onUpdated: () async {
                            final result = await getIt<ContactRepository>()
                                .getContact(_contact.id);
                            if (result case Success(:final data)) {
                              if (mounted) setState(() => _contact = data);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      _FilesSection(contactId: _contact.id),
                    ],
                  ),
                ),
                // ── Email tab ──
                _ContactEmailsSection(contactId: _contact.id),
                // ── Activity tab ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ContactNotesSection(contactId: _contact.id),
                      const SizedBox(height: 16),
                      ActivitiesSection(
                        entityType: 'contacts',
                        entityId: _contact.id,
                      ),
                    ],
                  ),
                ),
                // ── Related tab ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _ContactRecordsSection(contactId: _contact.id),
                ),
              ],
            ),
          ),
        ],
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
  const _ContactInfoCard({required this.contact, this.onFieldSaved});

  final Contact contact;
  final void Function(Contact updated)? onFieldSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EditableInfoRow(
              icon: Icons.email_outlined,
              label: l10n.contactEmail,
              value: contact.email,
              keyboardType: TextInputType.emailAddress,
              onSaved: (v) => _saveField(
                context,
                contact.copyWith(email: v),
              ),
            ),
            _EditableInfoRow(
              icon: Icons.phone_outlined,
              label: l10n.contactPhone,
              value: contact.phone ?? '',
              placeholder: 'Add phone',
              keyboardType: TextInputType.phone,
              onSaved: (v) => _saveField(
                context,
                contact.copyWith(
                  phone: v.isNotEmpty ? v : null,
                ),
              ),
            ),
            _EditableInfoRow(
              icon: Icons.work_outline,
              label: 'Job Title',
              value: contact.jobTitle ?? '',
              placeholder: 'Add job title',
              onSaved: (v) => _saveField(
                context,
                contact.copyWith(
                  jobTitle: v.isNotEmpty ? v : null,
                ),
              ),
            ),
            _EditableInfoRow(
              icon: Icons.source_outlined,
              label: l10n.contactSource,
              value: contact.source ?? '',
              placeholder: 'Add source',
              onSaved: (v) => _saveField(
                context,
                contact.copyWith(
                  source: v.isNotEmpty ? v : null,
                ),
              ),
            ),
            _CompanyRow(
              companyId: contact.companyId,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveField(BuildContext context, Contact updated) async {
    final result =
        await getIt<ContactRepository>().updateContact(updated);
    if (!context.mounted) return;
    switch (result) {
      case Success(:final data):
        onFieldSaved?.call(data);
      case Failure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${error.message}')),
        );
    }
  }
}

class _TagsCard extends StatefulWidget {
  const _TagsCard({required this.tags, required this.contactId, required this.contact, this.onUpdated});

  final List<String> tags;
  final String contactId;
  final Contact contact;
  final VoidCallback? onUpdated;

  @override
  State<_TagsCard> createState() => _TagsCardState();
}

class _TagsCardState extends State<_TagsCard> {
  List<String> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final response =
          await getIt<Dio>().get<Map<String, dynamic>>('/api/tags');
      final list = response.data?['data'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _availableTags = list
              .map((t) => (t as Map<String, dynamic>)['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _addTag(String tag) async {
    final updated = [...widget.tags, tag];
    await _saveTags(updated);
  }

  Future<void> _removeTag(String tag) async {
    final updated = widget.tags.where((t) => t != tag).toList();
    await _saveTags(updated);
  }

  Future<void> _saveTags(List<String> tags) async {
    try {
      final c = widget.contact;
      await getIt<ContactRepository>().updateContact(
        Contact(
          id: c.id,
          firstName: c.firstName,
          lastName: c.lastName,
          email: c.email,
          phone: c.phone,
          jobTitle: c.jobTitle,
          source: c.source,
          status: c.status,
          tags: tags,
          ownerId: c.ownerId,
          companyId: c.companyId,
          version: c.version,
          createdAt: c.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      widget.onUpdated?.call();
    } catch (_) {}
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
            Text(AppLocalizations.of(context)!.contactTags,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...widget.tags.map(
                  (tag) => CrmTagChip(
                    name: tag,
                    onDeleted: () => _removeTag(tag),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Add tag',
                  offset: const Offset(0, 32),
                  onSelected: _addTag,
                  itemBuilder: (_) => _availableTags
                      .where((t) => !widget.tags.contains(t))
                      .map((t) => PopupMenuItem(value: t, child: Text(t)))
                      .toList(),
                  child: Chip(
                    avatar: const Icon(Icons.add, size: 14),
                    label: const Text('Add'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableInfoRow extends StatefulWidget {
  const _EditableInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onSaved,
    this.placeholder,
    this.keyboardType,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? placeholder;
  final TextInputType? keyboardType;
  final ValueChanged<String> onSaved;

  @override
  State<_EditableInfoRow> createState() => _EditableInfoRowState();
}

class _EditableInfoRowState extends State<_EditableInfoRow> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_EditableInfoRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_editing) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final newValue = _ctrl.text.trim();
    setState(() => _editing = false);
    if (newValue != widget.value) {
      widget.onSaved(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_editing) {
      return ListTile(
        leading: Icon(widget.icon, color: theme.colorScheme.primary),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.label,
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check, size: 20),
              onPressed: _submit,
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
      );
    }

    final hasValue = widget.value.isNotEmpty;

    return ListTile(
      leading: Icon(widget.icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(widget.label, style: theme.textTheme.labelMedium),
      subtitle: Text(
        hasValue ? widget.value : (widget.placeholder ?? ''),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: hasValue ? null : theme.colorScheme.onSurfaceVariant,
          fontStyle: hasValue ? null : FontStyle.italic,
        ),
      ),
      trailing: Icon(
        Icons.edit_outlined,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      onTap: () => setState(() => _editing = true),
    );
  }
}

class _CompanyRow extends StatefulWidget {
  const _CompanyRow({required this.companyId});

  final String? companyId;

  @override
  State<_CompanyRow> createState() => _CompanyRowState();
}

class _CompanyRowState extends State<_CompanyRow> {
  Company? _company;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.companyId != null) _loadCompany();
  }

  Future<void> _loadCompany() async {
    setState(() => _loading = true);
    try {
      final company = await getIt<CompanyRemoteDataSource>()
          .getCompany(widget.companyId!);
      if (mounted) setState(() { _company = company; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.companyId == null) {
      return ListTile(
        leading: Icon(
          Icons.business_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text('Company', style: theme.textTheme.labelMedium),
        subtitle: Text(
          'No company linked',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (_loading) {
      return ListTile(
        leading: Icon(
          Icons.business_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text('Company', style: theme.textTheme.labelMedium),
        subtitle: const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final name = _company?.name ?? widget.companyId!;

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.tertiaryContainer,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onTertiaryContainer,
          ),
        ),
      ),
      title: Text('Company', style: theme.textTheme.labelMedium),
      subtitle: Text(
        name,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.primary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _company != null
          ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyDetailPage(company: _company!),
                ),
              )
          : null,
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

// ── Contact Email History ──────────────────────────────────────────────

class _ContactEmailsSection extends StatefulWidget {
  const _ContactEmailsSection({required this.contactId});
  final String contactId;

  @override
  State<_ContactEmailsSection> createState() => _ContactEmailsSectionState();
}

class _ContactEmailsSectionState extends State<_ContactEmailsSection> {
  List<Map<String, dynamic>>? _emails;
  bool _loading = true;
  int _visibleCount = 20;
  Map<String, dynamic>? _selectedEmail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final emails = await getIt<ContactRemoteDataSource>()
          .getContactEmails(widget.contactId);
      // Sort newest first.
      emails.sort((a, b) {
        final aTime = a['created_at'] as String? ?? a['sent_at'] as String? ?? '';
        final bTime = b['created_at'] as String? ?? b['sent_at'] as String? ?? '';
        return bTime.compareTo(aTime);
      });
      if (mounted) setState(() { _emails = emails; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _emails = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_emails == null || _emails!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 48,
                color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('No emails yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }

    // If an email is selected, show reading pane
    if (_selectedEmail != null) {
      return _buildReadingPane(context, _selectedEmail!);
    }

    // Gmail-style email list
    return Column(
      children: [
        // Header bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_emails!.length} email${_emails!.length == 1 ? '' : 's'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Email rows
        Expanded(
          child: ListView.separated(
            itemCount: _emails!.take(_visibleCount).length +
                (_emails!.length > _visibleCount ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= _emails!.take(_visibleCount).length) {
                return Center(
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _visibleCount += 20),
                    child: Text(
                      'Show more (${_emails!.length - _visibleCount} remaining)',
                    ),
                  ),
                );
              }
              final email = _emails![index];
              final subject =
                  email['subject'] as String? ?? '(no subject)';
              final body = email['text_body'] as String? ??
                  email['body'] as String? ??
                  email['body_html'] as String? ??
                  '';
              final from = email['from_address'] as String? ??
                  email['sender_email'] as String? ??
                  '';
              final timestamp = email['created_at'] as String? ??
                  email['sent_at'] as String? ??
                  '';
              final direction =
                  (email['direction'] as String? ?? '').toLowerCase();
              final isOutbound = direction == 'outbound' ||
                  direction == 'out' ||
                  direction == 'sent';

              return InkWell(
                onTap: () => setState(() => _selectedEmail = email),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOutbound
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 16,
                        color: isOutbound
                            ? colorScheme.primary
                            : colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          from.isNotEmpty ? from : 'You',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isOutbound ? null : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          subject,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          renderEmailBody(body),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReadingPane(
      BuildContext context, Map<String, dynamic> email) {
    final theme = Theme.of(context);
    final subject = email['subject'] as String? ?? '(no subject)';
    final body = email['text_body'] as String? ??
        email['body'] as String? ??
        email['body_html'] as String? ??
        '';
    final from = email['from_address'] as String? ??
        email['sender_email'] as String? ??
        '';
    final to = email['to_address'] as String? ??
        email['to'] as String? ??
        '';
    final cc = email['cc'] as String? ?? '';
    final timestamp = email['created_at'] as String? ??
        email['sent_at'] as String? ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to list'),
            onPressed: () => setState(() => _selectedEmail = null),
          ),
        ),
        const Divider(height: 1),
        // Email content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (from.isNotEmpty)
                  Text('From: $from',
                      style: theme.textTheme.bodyMedium),
                if (to.isNotEmpty)
                  Text('To: $to', style: theme.textTheme.bodySmall),
                if (cc.isNotEmpty)
                  Text('CC: $cc', style: theme.textTheme.bodySmall),
                if (timestamp.isNotEmpty)
                  Text(
                    _formatTimestamp(timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                HtmlEmailView(
                  body: body,
                  showToggle: true,
                  textStyle: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailBubble extends StatefulWidget {
  const _EmailBubble({
    required this.subject,
    required this.body,
    required this.from,
    required this.to,
    required this.timestamp,
    required this.isOutbound,
  });

  final String subject;
  final String body;
  final String from;
  final String to;
  final String timestamp;
  final bool isOutbound;

  @override
  State<_EmailBubble> createState() => _EmailBubbleState();
}

class _EmailBubbleState extends State<_EmailBubble> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: widget.isOutbound
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: widget.body.isNotEmpty
              ? () => setState(() => _expanded = !_expanded)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject + timestamp
                Row(
                  children: [
                    Icon(
                      widget.isOutbound
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: widget.isOutbound
                          ? colorScheme.primary
                          : colorScheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.subject,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.timestamp.isNotEmpty)
                      Text(
                        widget.timestamp,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // From / To
                if (widget.from.isNotEmpty)
                  Text(
                    'From: ${widget.from}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.to.isNotEmpty)
                  Text(
                    'To: ${widget.to}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Body preview (collapsed) or full (expanded)
                if (!_expanded && widget.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    renderEmailBody(widget.body),
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_expanded && widget.body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  HtmlEmailView(
                    body: widget.body,
                    showToggle: true,
                    textStyle: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
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
  final _noteCtrl = TextEditingController();
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final body = _noteCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _posting = true);
    _noteCtrl.clear();
    try {
      await getIt<ContactRemoteDataSource>()
          .addContactNote(widget.contactId, body);
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _posting = false);
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                    minLines: 1,
                    enabled: !_posting,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _posting ? null : _addNote,
                  icon: _posting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, size: 18),
                ),
              ],
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
