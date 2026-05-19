import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/repositories/timeline_repository.dart';
import 'package:cis_crm/features/pipeline/data/datasources/record_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_bloc.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

Color _parseColor(String colorStr) {
  if (colorStr.startsWith('#')) {
    final hex = colorStr.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
  return Color(int.tryParse(colorStr) ?? 0xFF9E9E9E);
}

class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({required this.recordId, super.key});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      builder: (context, recordState) {
        final l10n = AppLocalizations.of(context)!;
        if (recordState is! RecordLoaded) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.record)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final record = recordState.records.cast<PipelineRecord?>().firstWhere(
              (r) => r!.id == recordId,
              orElse: () => null,
            );

        if (record == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.record)),
            body: Center(child: Text(l10n.recordNotFound)),
          );
        }

        return _RecordDetailScaffold(record: record);
      },
    );
  }
}

class _RecordDetailScaffold extends StatelessWidget {
  const _RecordDetailScaffold({required this.record});

  final PipelineRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stage = _resolveStage(context, record.stageId);
    final pipelineName = _resolvePipelineName(context, record.pipelineId);

    return Scaffold(
      appBar: AppBar(
        title: Text(record.title),
        actions: [
          if (stage != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(stage.name),
                backgroundColor:
                    _parseColor(stage.color).withValues(alpha: 0.15),
                side: BorderSide(
                  color: _parseColor(stage.color).withValues(alpha: 0.4),
                ),
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: _parseColor(stage.color),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Claim',
            onPressed: () async {
              try {
                await GetIt.instance<RecordRemoteDataSource>()
                    .claimRecord(record.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Record claimed')),
                  );
                  context
                      .read<RecordBloc>()
                      .add(const RecordLoadRequested());
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to claim')),
                  );
                }
              }
            },
          ),
          PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context)!.moreActions,
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (menuContext) {
              final l10n = AppLocalizations.of(menuContext)!;
              return [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.edit),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                PopupMenuItem(
                  value: 'move',
                  child: ListTile(
                    leading: const Icon(Icons.drive_file_move_outlined),
                    title: Text(l10n.moveToStage),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete_outlined),
                    title: Text(l10n.delete),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Details card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.details,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.title,
                      label: AppLocalizations.of(context)!.title,
                      value: record.title,
                    ),
                    if (pipelineName != null)
                      _DetailRow(
                        icon: Icons.view_kanban_outlined,
                        label: AppLocalizations.of(context)!.pipeline,
                        value: pipelineName,
                      ),
                    if (stage != null)
                      _DetailRow(
                        icon: Icons.flag_outlined,
                        label: AppLocalizations.of(context)!.stage,
                        value: stage.name,
                      ),
                    if (record.contactId != null)
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: AppLocalizations.of(context)!.contact,
                        value: record.contactId!,
                      ),
                    if (record.ownerId != null)
                      _DetailRow(
                        icon: Icons.assignment_ind_outlined,
                        label: AppLocalizations.of(context)!.owner,
                        value: record.ownerId!,
                      ),
                    _DetailRow(
                      icon: Icons.source_outlined,
                      label: AppLocalizations.of(context)!.source,
                      value: record.source.name,
                    ),
                    if (record.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.label_outline,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: record.tags
                                  .map(
                                    (tag) => Chip(
                                      label: Text(tag),
                                      labelStyle: theme.textTheme.labelSmall,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      side: BorderSide(
                                        color: colorScheme.outlineVariant,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: AppLocalizations.of(context)!.created,
                      value: _formatDate(record.createdAt),
                    ),
                    _DetailRow(
                      icon: Icons.update_outlined,
                      label: AppLocalizations.of(context)!.updated,
                      value: _formatDate(record.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Notes ──
            _NotesSection(recordId: record.id),
            const SizedBox(height: 16),

            // ── Linked Contacts ──
            _LinkedContactsSection(recordId: record.id),
            const SizedBox(height: 16),

            // ── Emails ──
            _EmailsSection(recordId: record.id),
            const SizedBox(height: 16),

            // ── Files ──
            _RecordFilesSection(recordId: record.id),
            const SizedBox(height: 16),

            // ── Timeline ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.timeline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    _TimelineSection(recordId: record.id),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stage? _resolveStage(BuildContext context, String stageId) {
    final pipelineState = context.read<PipelineBloc>().state;
    if (pipelineState is! PipelineLoaded) return null;
    final stages = pipelineState.kanbanStages;
    if (stages == null) return null;
    return stages
        .cast<Stage?>()
        .firstWhere((s) => s!.id == stageId, orElse: () => null);
  }

  String? _resolvePipelineName(BuildContext context, String pipelineId) {
    final pipelineState = context.read<PipelineBloc>().state;
    if (pipelineState is! PipelineLoaded) return null;
    final pipeline = pipelineState.pipelines.cast<Pipeline?>().firstWhere(
          (p) => p!.id == pipelineId,
          orElse: () => null,
        );
    return pipeline?.name ?? pipelineState.kanbanPipeline?.name;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showEditDialog(context);
      case 'move':
        _showMoveDialog(context);
      case 'delete':
        _confirmDelete(context);
    }
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.deleteRecordConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) {
      if ((confirmed ?? false) && context.mounted) {
        context.read<RecordBloc>().add(
              RecordDeleteRequested(recordId: record.id),
            );
        Navigator.of(context).pop();
      }
    });
  }

  void _showMoveDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pipelineState = context.read<PipelineBloc>().state;
    final stages = pipelineState is PipelineLoaded
        ? pipelineState.kanbanStages ?? <Stage>[]
        : <Stage>[];

    if (stages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noStagesAvailable)),
      );
      return;
    }

    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? selectedStageId;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(l10n.moveToStage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: stages
                  .map(
                    (stage) => RadioListTile<String>(
                      title: Text(stage.name),
                      value: stage.id,
                      groupValue: selectedStageId,
                      onChanged: (v) =>
                          setDialogState(() => selectedStageId = v),
                    ),
                  )
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: selectedStageId != null
                    ? () => Navigator.of(dialogContext).pop(selectedStageId)
                    : null,
                child: Text(l10n.move),
              ),
            ],
          ),
        );
      },
    ).then((stageId) {
      if (stageId != null && context.mounted) {
        context.read<RecordBloc>().add(
              RecordMoveRequested(recordId: record.id, toStageId: stageId),
            );
      }
    });
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: record.title);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Record'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Enter record title',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              context.read<RecordBloc>().add(
                    RecordUpdateRequested(
                      id: record.id,
                      title: title,
                    ),
                  );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatefulWidget {
  const _NotesSection({required this.recordId});

  final String recordId;

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  List<Map<String, dynamic>>? _notes;
  bool _loading = true;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await GetIt.instance<RecordRemoteDataSource>()
          .getNotes(widget.recordId);
      if (mounted) setState(() { _notes = notes; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _notes = []; _loading = false; });
    }
  }

  Future<void> _addNote() async {
    final body = _noteController.text.trim();
    if (body.isEmpty) return;
    _noteController.clear();
    try {
      await GetIt.instance<RecordRemoteDataSource>()
          .addNote(widget.recordId, body);
      await _loadNotes();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add note')),
        );
      }
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 24),
            // Add note field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addNote,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    color: theme.colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['body'] as String? ?? '',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note['created_at'] as String? ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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

class _LinkedContactsSection extends StatefulWidget {
  const _LinkedContactsSection({required this.recordId});

  final String recordId;

  @override
  State<_LinkedContactsSection> createState() =>
      _LinkedContactsSectionState();
}

class _LinkedContactsSectionState extends State<_LinkedContactsSection> {
  List<Map<String, dynamic>>? _contacts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await GetIt.instance<RecordRemoteDataSource>()
          .getLinkedContacts(widget.recordId);
      if (mounted) {
        setState(() { _contacts = contacts; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _contacts = []; _loading = false; });
    }
  }

  void _showLinkDialog() {
    final contactIdCtrl = TextEditingController();
    var role = 'champion';
    final roles = ['champion', 'decision_maker', 'budget_holder', 'user'];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Link Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contactIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact ID',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => role = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final id = contactIdCtrl.text.trim();
                if (id.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await GetIt.instance<RecordRemoteDataSource>()
                      .linkContact(widget.recordId, id, role);
                  await _loadContacts();
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to link contact'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Link'),
            ),
          ],
        ),
      ),
    );
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Linked Contacts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  tooltip: 'Link contact',
                  onPressed: _showLinkDialog,
                ),
              ],
            ),
            const Divider(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_contacts == null || _contacts!.isEmpty)
              Text(
                'No linked contacts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...(_contacts!).map(
                (c) {
                  final contact =
                      c['contact'] as Map<String, dynamic>? ?? c;
                  final data =
                      contact['data'] as Map<String, dynamic>? ?? {};
                  final name =
                      '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'
                          .trim();
                  final role = c['role'] as String? ?? '';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(name.isNotEmpty ? name : 'Contact'),
                    subtitle: Text(role),
                    trailing: IconButton(
                      icon: const Icon(Icons.link_off),
                      tooltip: 'Unlink',
                      onPressed: () async {
                        final contactId =
                            contact['id'] as String? ?? '';
                        if (contactId.isEmpty) return;
                        try {
                          await GetIt.instance<RecordRemoteDataSource>()
                              .unlinkContact(
                            widget.recordId,
                            contactId,
                          );
                          await _loadContacts();
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to unlink'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EmailsSection extends StatefulWidget {
  const _EmailsSection({required this.recordId});
  final String recordId;

  @override
  State<_EmailsSection> createState() => _EmailsSectionState();
}

class _EmailsSectionState extends State<_EmailsSection> {
  List<Map<String, dynamic>>? _emails;
  bool _loading = true;
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final emails = await GetIt.instance<RecordRemoteDataSource>()
          .getEmails(widget.recordId);
      if (mounted) setState(() { _emails = emails; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _emails = []; _loading = false; });
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
              'Emails',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_emails == null || _emails!.isEmpty)
              Text(
                'No emails linked to this record',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...(_emails!).map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.email_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    e['subject'] as String? ?? 'No subject',
                  ),
                  subtitle: Text(
                    e['from_address'] as String? ??
                        e['sender_email'] as String? ??
                        '',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordFilesSection extends StatefulWidget {
  const _RecordFilesSection({required this.recordId});
  final String recordId;

  @override
  State<_RecordFilesSection> createState() => _RecordFilesSectionState();
}

class _RecordFilesSectionState extends State<_RecordFilesSection> {
  List<Map<String, dynamic>>? _files;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await GetIt.instance<Dio>().get<Map<String, dynamic>>(
        '/api/files',
        queryParameters: {
          'parent_type': 'record',
          'parent_id': widget.recordId,
        },
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _files = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _files = []; _loading = false; });
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
              'Files',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_files == null || _files!.isEmpty)
              Text(
                'No files attached',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...(_files!).map(
                (f) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file),
                  title: Text(
                    f['filename'] as String? ?? 'File',
                  ),
                  subtitle: Text(
                    f['content_type'] as String? ?? '',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FutureBuilder(
      future: GetIt.instance<TimelineRepository>().getTimeline(
        entityType: 'record',
        entityId: recordId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.timelineLoadFailed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          );
        }

        final result = snapshot.data!;
        return switch (result) {
          Success(:final data) when data.isEmpty => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.timeline_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noTimelineEntries,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Success(:final data) => Column(
              children: data
                  .map(
                    (entry) => ListTile(
                      leading: Icon(
                        _timelineIcon(entry.eventType),
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(entry.summary),
                      subtitle: Text(_formatDateTime(entry.createdAt)),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          Failure() => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.timelineLoadFailed,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
        };
      },
    );
  }

  IconData _timelineIcon(String eventType) {
    return switch (eventType) {
      'stage_change' => Icons.swap_horiz,
      'note_added' => Icons.note_add_outlined,
      'email_sent' => Icons.email_outlined,
      'call_logged' => Icons.phone_outlined,
      'file_uploaded' => Icons.attach_file,
      'task_completed' => Icons.task_alt,
      _ => Icons.circle_outlined,
    };
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
