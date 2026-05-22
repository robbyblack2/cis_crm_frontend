import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/activities_section.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/domain/repositories/company_repository.dart';
import 'package:cis_crm/features/contacts/presentation/widgets/entity_tags_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CompanyDetailPage extends StatefulWidget {
  const CompanyDetailPage({required this.company, super.key});

  final Company company;

  @override
  State<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage>
    with TickerProviderStateMixin {
  late Company _company;
  late final TabController _tabController;

  // Inline editing state
  bool _editingName = false;
  bool _editingDomain = false;
  bool _editingIndustry = false;
  bool _editingPhone = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _domainCtrl;
  late final TextEditingController _industryCtrl;
  late final TextEditingController _phoneCtrl;

  // Notes
  List<Map<String, dynamic>>? _notes;
  bool _notesLoading = true;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _company = widget.company;
    _tabController = TabController(length: 4, vsync: this);
    _nameCtrl = TextEditingController(text: _company.name);
    _domainCtrl = TextEditingController(text: _company.domain ?? '');
    _industryCtrl = TextEditingController(text: _company.industry ?? '');
    _phoneCtrl = TextEditingController(text: _company.phone ?? '');
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _domainCtrl.dispose();
    _industryCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveField(String field, String value) async {
    try {
      await getIt<Dio>().put<void>(
        '/api/companies/${_company.id}',
        data: {
          'data': {field: value},
          'tags': _company.tags,
          'version': _company.version,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _reload() async {
    try {
      final ds = getIt<CompanyRemoteDataSource>();
      final updated = await ds.getCompany(_company.id);
      if (mounted) setState(() => _company = updated);
    } catch (_) {}
  }

  Future<void> _loadNotes() async {
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/companies/${_company.id}/notes',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _notes = list?.cast<Map<String, dynamic>>() ?? [];
          _notesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _notes = []; _notesLoading = false; });
    }
  }

  Future<void> _addNote() async {
    final body = _noteCtrl.text.trim();
    if (body.isEmpty) return;
    _noteCtrl.clear();
    try {
      await getIt<Dio>().post<void>(
        '/api/companies/${_company.id}/notes',
        data: {'body': body},
      );
      await _loadNotes();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add note')),
        );
      }
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 7) return '${dt.month}/${dt.day}/${dt.year}';
      if (diff.inDays > 0) {
        return diff.inDays == 1 ? 'Yesterday' : '${diff.inDays}d ago';
      }
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_company.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            tooltip: 'Delete company',
            onPressed: () => _confirmDelete(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Contacts'),
            Tab(icon: Icon(Icons.email_outlined, size: 18), text: 'Email'),
            Tab(icon: Icon(Icons.history_outlined, size: 18), text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Overview tab ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Details',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const Divider(height: 24),
                        _editableRow(
                          icon: Icons.business,
                          label: 'Name',
                          value: _company.name,
                          controller: _nameCtrl,
                          editing: _editingName,
                          onToggle: () =>
                              setState(() => _editingName = !_editingName),
                          onSave: () {
                            _saveField('name', _nameCtrl.text.trim());
                            setState(() => _editingName = false);
                          },
                        ),
                        _editableRow(
                          icon: Icons.language,
                          label: 'Website',
                          value: _company.domain ?? '+ Add website',
                          isPlaceholder: _company.domain == null,
                          controller: _domainCtrl,
                          editing: _editingDomain,
                          onToggle: () =>
                              setState(() => _editingDomain = !_editingDomain),
                          onSave: () {
                            _saveField('website', _domainCtrl.text.trim());
                            setState(() => _editingDomain = false);
                          },
                        ),
                        _editableRow(
                          icon: Icons.category_outlined,
                          label: 'Industry',
                          value: _company.industry ?? '+ Add industry',
                          isPlaceholder: _company.industry == null,
                          controller: _industryCtrl,
                          editing: _editingIndustry,
                          onToggle: () => setState(
                              () => _editingIndustry = !_editingIndustry),
                          onSave: () {
                            _saveField('industry', _industryCtrl.text.trim());
                            setState(() => _editingIndustry = false);
                          },
                        ),
                        _editableRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _company.phone ?? '+ Add phone',
                          isPlaceholder: _company.phone == null,
                          controller: _phoneCtrl,
                          editing: _editingPhone,
                          onToggle: () =>
                              setState(() => _editingPhone = !_editingPhone),
                          onSave: () {
                            _saveField('phone', _phoneCtrl.text.trim());
                            setState(() => _editingPhone = false);
                          },
                        ),
                        // Tags
                        const SizedBox(height: 12),
                        _CompanyTagsSection(
                          company: _company,
                          onUpdated: () => _reload(),
                        ),
                        const SizedBox(height: 8),
                        _infoRow(theme, 'Created',
                            '${_company.createdAt.day}/${_company.createdAt.month}/${_company.createdAt.year}'),
                        _infoRow(theme, 'Updated',
                            '${_company.updatedAt.day}/${_company.updatedAt.month}/${_company.updatedAt.year}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Notes section
                _buildNotesSection(theme, colorScheme),
              ],
            ),
          ),

          // ── Contacts tab ──
          _RelatedListTab(
            future: getIt<CompanyRemoteDataSource>()
                .getCompanyContacts(_company.id),
            emptyText: 'No contacts linked',
            itemBuilder: (item) {
              final d = item['data'] as Map<String, dynamic>? ?? {};
              final name =
                  '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'.trim();
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(name.isNotEmpty ? name : 'Contact'),
                subtitle: Text(d['email'] as String? ?? ''),
              );
            },
          ),

          // ── Email tab ──
          _CompanyEmailsSection(companyId: _company.id),

          // ── Activity tab ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ActivitiesSection(
              entityType: 'companies',
              entityId: _company.id,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableRow({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    required bool editing,
    required VoidCallback onToggle,
    required VoidCallback onSave,
    bool isPlaceholder = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (editing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  labelText: label,
                ),
                onSubmitted: (_) => onSave(),
                onTapOutside: (_) => onSave(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, size: 18),
              onPressed: onSave,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isPlaceholder ? colorScheme.primary : null,
                  fontStyle: isPlaceholder ? FontStyle.italic : null,
                ),
              ),
            ),
            Icon(Icons.edit_outlined, size: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 20,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme, ColorScheme colorScheme) {
    final sortedNotes = _notes != null
        ? (List<Map<String, dynamic>>.from(_notes!)
          ..sort((a, b) {
            final aTs = a['created_at'] as String? ?? '';
            final bTs = b['created_at'] as String? ?? '';
            return bTs.compareTo(aTs);
          }))
        : <Map<String, dynamic>>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes${sortedNotes.isNotEmpty ? ' (${sortedNotes.length})' : ''}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => _addNote(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addNote,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_notesLoading)
              const Center(child: CircularProgressIndicator())
            else if (sortedNotes.isEmpty)
              Text('No notes yet',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant))
            else
              ...sortedNotes.map((note) {
                final body = note['body'] as String? ?? '';
                final ts = _relativeTime(note['created_at'] as String?);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ts,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(body,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Company?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await getIt<CompanyRemoteDataSource>().deleteCompany(_company.id);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}

class _RelatedListTab extends StatelessWidget {
  const _RelatedListTab({
    required this.future,
    required this.emptyText,
    required this.itemBuilder,
  });

  final Future<List<Map<String, dynamic>>> future;
  final String emptyText;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }
}

/// Loads and displays emails linked to a company.
class _CompanyEmailsSection extends StatefulWidget {
  const _CompanyEmailsSection({required this.companyId});

  final String companyId;

  @override
  State<_CompanyEmailsSection> createState() => _CompanyEmailsSectionState();
}

class _CompanyEmailsSectionState extends State<_CompanyEmailsSection> {
  List<Map<String, dynamic>>? _emails;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/companies/${widget.companyId}/emails',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _emails = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _emails = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_emails == null || _emails!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'No emails yet',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _emails!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final email = _emails![index];
        final subject = email['subject'] as String? ?? '(no subject)';
        final from = email['from_address'] as String? ??
            email['sender_email'] as String? ??
            '';
        final timestamp = email['created_at'] as String? ??
            email['sent_at'] as String? ??
            '';
        final body = email['text_body'] as String? ??
            email['body'] as String? ??
            '';
        final direction =
            (email['direction'] as String? ?? '').toLowerCase();
        final isOutbound = direction == 'outbound' || direction == 'sent';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isOutbound
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: isOutbound ? cs.primary : cs.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subject,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (timestamp.isNotEmpty)
                      Text(
                        _fmtTs(timestamp),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
                if (from.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'From: $from',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtTs(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

/// Company tags section with add/remove, uses EntityTagsCard.
class _CompanyTagsSection extends StatefulWidget {
  const _CompanyTagsSection({required this.company, this.onUpdated});

  final Company company;
  final VoidCallback? onUpdated;

  @override
  State<_CompanyTagsSection> createState() => _CompanyTagsSectionState();
}

class _CompanyTagsSectionState extends State<_CompanyTagsSection> {
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
              .map((t) =>
                  (t as Map<String, dynamic>)['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveTags(List<String> tags) async {
    try {
      final c = widget.company;
      await getIt<CompanyRepository>().updateCompany(
        Company(
          id: c.id,
          name: c.name,
          tags: tags,
          ownerId: c.ownerId,
          domain: c.domain,
          industry: c.industry,
          phone: c.phone,
          employeeCount: c.employeeCount,
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
    return EntityTagsCard(
      tags: widget.company.tags,
      availableTags: _availableTags,
      onTagsChanged: _saveTags,
      title: 'Tags',
    );
  }
}
