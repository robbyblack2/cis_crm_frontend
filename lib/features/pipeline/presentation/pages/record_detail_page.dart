import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/utils/html_utils.dart';
import 'package:cis_crm/core/widgets/html_email_view.dart';
import 'package:cis_crm/core/utils/name_resolver.dart';
import 'package:cis_crm/core/widgets/activities_section.dart';
import 'package:cis_crm/core/widgets/search_or_create_field.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/models/contact_model.dart';
import 'package:file_picker/file_picker.dart';
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

String _fmtTs(String? iso) {
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

class _RecordDetailScaffold extends StatefulWidget {
  const _RecordDetailScaffold({required this.record});

  final PipelineRecord record;

  @override
  State<_RecordDetailScaffold> createState() => _RecordDetailScaffoldState();
}

class _RecordDetailScaffoldState extends State<_RecordDetailScaffold>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Email-sourced records default to Conversation tab (index 1).
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.record.source == RecordSource.email ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  PipelineRecord get record => widget.record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stage = _resolveStage(context, record.stageId);
    final pipelineName = _resolvePipelineName(context, record.pipelineId);

    return Scaffold(
      appBar: AppBar(
        title: Text(record.title),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.forum_outlined, size: 18), text: 'Conversation'),
            Tab(icon: Icon(Icons.history_outlined, size: 18), text: 'Activity'),
            Tab(icon: Icon(Icons.link_outlined, size: 18), text: 'Related'),
          ],
        ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Overview (Details + Notes) ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RecordDetailsCard(
                  record: record,
                  stage: stage,
                  pipelineName: pipelineName,
                  onShowAddTagDialog: () =>
                      _showAddTagDialog(context, record),
                ),
                if (record.source == RecordSource.email) ...[
                  const SizedBox(height: 16),
                  _OriginalEmailPreview(
                    recordId: record.id,
                    onViewFull: () => _tabController.animateTo(1),
                  ),
                ],
                const SizedBox(height: 16),
                _NotesSection(recordId: record.id),
              ],
            ),
          ),

          // ── Tab 2: Conversation ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _ConversationSection(
              recordId: record.id,
              isEmailSourced: record.source == RecordSource.email,
            ),
          ),

          // ── Tab 3: Activity (Timeline + Activities) ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                const SizedBox(height: 16),
                ActivitiesSection(
                  entityType: 'records',
                  entityId: record.id,
                ),
              ],
            ),
          ),

          // ── Tab 4: Related (Contacts + Files) ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _LinkedContactsSection(recordId: record.id),
                const SizedBox(height: 16),
                _RecordFilesSection(recordId: record.id),
              ],
            ),
          ),
        ],
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

  void _showAddTagDialog(BuildContext context, PipelineRecord record) {
    final tagCtrl = TextEditingController();
    List<String> serverTags = [];
    bool loadingTags = true;

    // Tag color hash (same as tags_page.dart)
    const tagColors = [
      Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
      Color(0xFF22C55E), Color(0xFF14B8A6), Color(0xFF3B82F6),
      Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
      Color(0xFF64748B), Color(0xFF78716C), Color(0xFF0EA5E9),
    ];
    Color colorForTag(String name) {
      var hash = 0;
      for (var i = 0; i < name.length; i++) {
        hash = name.codeUnitAt(i) + ((hash << 5) - hash);
      }
      return tagColors[hash.abs() % tagColors.length];
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Fetch tags on first build
          if (loadingTags) {
            GetIt.instance<Dio>()
                .get<Map<String, dynamic>>('/api/tags')
                .then((response) {
              final list = response.data?['data'] as List<dynamic>? ?? [];
              final names = list
                  .cast<Map<String, dynamic>>()
                  .map((t) => t['name'] as String? ?? '')
                  .where((n) => n.isNotEmpty)
                  .toList();
              setSheetState(() {
                serverTags = names;
                loadingTags = false;
              });
            }).catchError((_) {
              setSheetState(() => loadingTags = false);
            });
          }

          final query = tagCtrl.text.trim().toLowerCase();
          final existingTags = record.tags.map((t) => t.toLowerCase()).toSet();
          final available = serverTags
              .where((t) => !existingTags.contains(t.toLowerCase()))
              .where(
                (t) => query.isEmpty || t.toLowerCase().contains(query),
              )
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Tag',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Search or create a tag',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 12),
                if (loadingTags)
                  const Center(child: CircularProgressIndicator())
                else if (available.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: available.map((tag) {
                          final color = colorForTag(tag);
                          return ActionChip(
                            avatar: CircleAvatar(
                              radius: 6,
                              backgroundColor: color,
                            ),
                            label: Text(tag),
                            backgroundColor:
                                color.withValues(alpha: 0.08),
                            side: BorderSide(
                              color: color.withValues(alpha: 0.3),
                            ),
                            onPressed: () {
                              final updatedTags = [...record.tags, tag];
                              context.read<RecordBloc>().add(
                                    RecordUpdateRequested(
                                      id: record.id,
                                      title: record.title,
                                      tags: updatedTags,
                                    ),
                                  );
                              Navigator.pop(ctx);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                if (query.isNotEmpty &&
                    !serverTags
                        .any((t) => t.toLowerCase() == query)) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text('Create "$query"'),
                    onPressed: () {
                      final updatedTags = [
                        ...record.tags,
                        tagCtrl.text.trim(),
                      ];
                      context.read<RecordBloc>().add(
                            RecordUpdateRequested(
                              id: record.id,
                              title: record.title,
                              tags: updatedTags,
                            ),
                          );
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
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
  bool _posting = false;
  final _noteController = TextEditingController();
  final _noteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    NameResolver.instance.loadUsers();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
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
    setState(() => _posting = true);
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
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 7) return _fmtTs(iso);
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
    final noteCount = _notes?.length ?? 0;

    // Sort newest first
    final sortedNotes = _notes != null
        ? List<Map<String, dynamic>>.from(_notes!)
        : <Map<String, dynamic>>[];
    sortedNotes.sort((a, b) {
      final aTime = a['created_at'] as String? ?? '';
      final bTime = b['created_at'] as String? ?? '';
      return bTime.compareTo(aTime);
    });

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
                    'Notes${noteCount > 0 ? ' ($noteCount)' : ''}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Add note field with Ctrl+Enter support
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      // Ctrl+Enter handled via onSubmitted
                    },
                    child: TextField(
                      controller: _noteController,
                      focusNode: _noteFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Add a note...',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        suffixIcon: _posting
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      maxLines: 6,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _addNote(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _posting ? null : _addNote,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
            if (_posting)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Posting...'),
              ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (sortedNotes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No notes yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...sortedNotes.map(
                (note) {
                  final authorId = note['created_by'] as String?;
                  final authorName =
                      NameResolver.instance.userName(authorId);
                  return _NoteItem(
                    body: note['body'] as String? ?? '',
                    timestamp:
                        _relativeTime(note['created_at'] as String?),
                    authorId: authorId,
                    authorName: authorName,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteItem extends StatefulWidget {
  const _NoteItem({
    required this.body,
    required this.timestamp,
    this.authorId,
    this.authorName,
  });

  final String body;
  final String timestamp;
  final String? authorId;
  final String? authorName;

  @override
  State<_NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<_NoteItem> {
  bool _expanded = false;

  String get _displayName {
    if (widget.authorName != null && widget.authorName!.isNotEmpty) {
      return widget.authorName!;
    }
    if (widget.authorId != null && widget.authorId!.isNotEmpty) {
      return widget.authorId!;
    }
    return 'Unknown';
  }

  String get _initials {
    final name = _displayName;
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLong = widget.body.length > 150 || widget.body.contains('\n');

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + author + timestamp + overflow
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    _initials,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.timestamp,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(28, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Copy text'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (action) {
                    if (action == 'copy') {
                      // Copy to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Note copied')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Body with truncation
            Text(
              widget.body,
              style: theme.textTheme.bodyMedium,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (isLong && !_expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Show more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (isLong && _expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Show less',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
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

  static const _roleLabels = {
    'user': 'User',
    'champion': 'Champion',
    'decision_maker': 'Decision Maker',
    'budget_holder': 'Budget Holder',
  };

  Future<List<Map<String, dynamic>>> _searchContacts(String query) async {
    final response = await GetIt.instance<ContactRemoteDataSource>()
        .getContacts(page: 1, perPage: 10);
    final q = query.toLowerCase();
    return response.items
        .where((c) {
          final name = '${c.firstName} ${c.lastName}'.toLowerCase();
          return name.contains(q) || c.email.toLowerCase().contains(q);
        })
        .map((c) => {
              'id': c.id,
              'name': '${c.firstName} ${c.lastName}'.trim(),
              'email': c.email,
            })
        .toList();
  }

  Future<Map<String, dynamic>?> _createContactFromQuery(
    String query,
  ) async {
    final hints = QueryParser.parseContactQuery(query);
    final firstCtrl =
        TextEditingController(text: hints.firstName ?? '');
    final lastCtrl =
        TextEditingController(text: hints.lastName ?? '');
    final emailCtrl =
        TextEditingController(text: hints.email ?? '');
    final phoneCtrl =
        TextEditingController(text: hints.phone ?? '');

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quick Add Contact',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: firstCtrl,
                decoration: const InputDecoration(
                  labelText: 'First name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lastCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final first = firstCtrl.text.trim();
                  if (first.isEmpty) return;
                  try {
                    final contact = ContactModel(
                      id: '',
                      firstName: first,
                      lastName: lastCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isNotEmpty
                          ? phoneCtrl.text.trim()
                          : null,
                      status: 'lead',
                      tags: const [],
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    final created =
                        await GetIt.instance<ContactRemoteDataSource>()
                            .createContact(contact);
                    if (ctx.mounted) {
                      Navigator.pop(ctx, {
                        'id': created.id,
                        'name':
                            '${created.firstName} ${created.lastName}'
                                .trim(),
                        'email': created.email,
                      });
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create Contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinkDialog() {
    String? selectedContactId;
    Map<String, dynamic>? selectedContact;
    var role = 'user';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Link Contact',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),

                SearchOrCreateField<Map<String, dynamic>>(
                  label: 'Search contacts by name or email',
                  onSearch: _searchContacts,
                  itemLabel: (c) => c['name'] as String? ?? '',
                  itemSubtitle: (c) => c['email'] as String? ?? '',
                  createEntityLabel: 'contact',
                  selectedItem: selectedContact,
                  onSelected: (c) => setSheetState(() {
                    selectedContactId = c['id'] as String?;
                    selectedContact = c;
                  }),
                  onCleared: () => setSheetState(() {
                    selectedContactId = null;
                    selectedContact = null;
                  }),
                  onCreateTapped: _createContactFromQuery,
                ),

                const SizedBox(height: 12),

                // Role selector
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: _roleLabels.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => role = v);
                  },
                ),

                const SizedBox(height: 20),

                FilledButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Link Contact'),
                  onPressed: selectedContactId == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            await GetIt.instance<RecordRemoteDataSource>()
                                .linkContact(
                              widget.recordId,
                              selectedContactId!,
                              role,
                            );
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
                ),
              ],
            ),
          ),
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
                  final email = data['email'] as String? ??
                      contact['email'] as String? ??
                      '';
                  final roleLabel =
                      _LinkedContactsSectionState._roleLabels[role] ?? role;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(name.isNotEmpty ? name : 'Contact'),
                    subtitle: Text(
                      [
                        if (email.isNotEmpty) email,
                        roleLabel,
                      ].join(' · '),
                    ),
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

/// Shows a brief email preview card on the Overview tab for email-sourced records.
class _OriginalEmailPreview extends StatefulWidget {
  const _OriginalEmailPreview({
    required this.recordId,
    required this.onViewFull,
  });

  final String recordId;
  final VoidCallback onViewFull;

  @override
  State<_OriginalEmailPreview> createState() => _OriginalEmailPreviewState();
}

class _OriginalEmailPreviewState extends State<_OriginalEmailPreview> {
  Map<String, dynamic>? _firstMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ds = GetIt.instance<RecordRemoteDataSource>();
      var messages = await ds.getConversation(widget.recordId);

      // Fall back to /emails if conversation is empty.
      if (messages.isEmpty) {
        try {
          messages = await ds.getEmails(widget.recordId);
        } catch (_) {}
      }

      if (mounted) {
        // Normalize nested data structure if present.
        Map<String, dynamic>? first;
        if (messages.isNotEmpty) {
          final raw = messages.first;
          final data = raw['data'];
          if (data is Map<String, dynamic>) {
            first = {
              ...data,
              if (data['created_at'] == null && raw['timestamp'] != null)
                'created_at': raw['timestamp'],
            };
          } else {
            first = raw;
          }
        }
        setState(() {
          _firstMessage = first;
          _loading = false;
        });
      }
    } catch (_) {
      // Try /emails as last resort.
      try {
        final emails = await GetIt.instance<RecordRemoteDataSource>()
            .getEmails(widget.recordId);
        if (mounted) {
          setState(() {
            _firstMessage = emails.isNotEmpty ? emails.first : null;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.email_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('Loading email...', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    if (_firstMessage == null) return const SizedBox.shrink();

    final msg = _firstMessage!;
    final from = msg['from_address'] as String? ??
        msg['sender_email'] as String? ??
        '';
    final subject = msg['subject'] as String? ?? '(no subject)';
    final body = renderEmailBody(
      msg['body_html'] as String? ??
          msg['html_body'] as String? ??
          msg['body_text'] as String? ??
          msg['text_body'] as String? ??
          msg['body'] as String? ??
          '',
    );
    final timestamp = msg['created_at'] as String? ??
        msg['sent_at'] as String? ??
        '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Original Email',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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
            const Divider(height: 16),
            if (from.isNotEmpty)
              Text(
                'From: $from',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            const SizedBox(height: 4),
            Text(
              'Subject: $subject',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onViewFull,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View full email'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationSection extends StatefulWidget {
  const _ConversationSection({
    required this.recordId,
    this.isEmailSourced = false,
  });
  final String recordId;
  final bool isEmailSourced;

  @override
  State<_ConversationSection> createState() => _ConversationSectionState();
}


class _ConversationSectionState extends State<_ConversationSection> {
  List<Map<String, dynamic>>? _messages;
  bool _loading = true;
  int _visibleThreads = 20;
  final Set<String> _expandedThreads = {};
  List<_EmailThread>? _cachedThreads;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ds = GetIt.instance<RecordRemoteDataSource>();

      // Try /conversation first (combined emails + notes).
      var messages = await ds.getConversation(widget.recordId);

      // If conversation is empty, fall back to /emails endpoint.
      if (messages.isEmpty) {
        try {
          messages = await ds.getEmails(widget.recordId);
        } catch (_) {}
      }

      if (mounted) {
        _cachedThreads = null;
        setState(() {
          _messages = messages;
          _loading = false;
        });
        final threads = _buildThreads();
        setState(() {
          for (final t in threads) {
            _expandedThreads.add(t.key);
          }
        });
      }
    } catch (_) {
      // Even if /conversation fails, try /emails before giving up.
      try {
        final emails = await GetIt.instance<RecordRemoteDataSource>()
            .getEmails(widget.recordId);
        if (mounted) {
          _cachedThreads = null;
          setState(() {
            _messages = emails;
            _loading = false;
          });
          final threads = _buildThreads();
          setState(() {
            for (final t in threads) {
              _expandedThreads.add(t.key);
            }
          });
        }
      } catch (_) {
        if (mounted) setState(() { _messages = []; _loading = false; });
      }
    }
  }

  /// Normalizes a conversation item — if it has a nested `data` field
  /// (from /conversation endpoint), flatten it so email fields are at top level.
  Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final type = raw['type'] as String?;
    final data = raw['data'];
    if (type != null && data is Map<String, dynamic>) {
      // Merge the nested data with the wrapper, preserving type and timestamp.
      return {
        ...data,
        'type': type,
        'timestamp': raw['timestamp'],
        if (data['created_at'] == null && raw['timestamp'] != null)
          'created_at': raw['timestamp'],
      };
    }
    return raw;
  }

  /// Group messages into threads by normalized subject (memoized).
  List<_EmailThread> _buildThreads() {
    if (_cachedThreads != null) return _cachedThreads!;
    if (_messages == null || _messages!.isEmpty) return [];

    // Filter to email items only (skip notes) and normalize.
    final emails = _messages!
        .map(_normalize)
        .where((m) => m['type'] != 'note')
        .toList();

    if (emails.isEmpty) return [];

    final threadMap = <String, List<Map<String, dynamic>>>{};
    for (final msg in emails) {
      final subject = (msg['subject'] as String? ?? '(no subject)')
          .replaceAll(RegExp(r'^(Re|Fwd|Fw):\s*', caseSensitive: false), '')
          .trim();
      final key = subject.toLowerCase();
      threadMap.putIfAbsent(key, () => []).add(msg);
    }

    final threads = threadMap.entries.map((e) {
      // Sort messages within thread oldest first
      e.value.sort((a, b) {
        final aTs = a['created_at'] as String? ??
            a['timestamp'] as String? ??
            '';
        final bTs = b['created_at'] as String? ??
            b['timestamp'] as String? ??
            '';
        return aTs.compareTo(bTs);
      });
      final latest = e.value.last;
      final subject = latest['subject'] as String? ?? '(no subject)';
      final latestTs = latest['created_at'] as String? ?? '';
      return _EmailThread(
        key: e.key,
        subject: subject,
        messages: e.value,
        latestTimestamp: latestTs,
      );
    }).toList();

    // Sort threads newest first
    threads.sort((a, b) => b.latestTimestamp.compareTo(a.latestTimestamp));
    _cachedThreads = threads;
    return threads;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final threads = _buildThreads();
    final totalCount = _messages?.length ?? 0;
    final visibleThreads = threads.take(_visibleThreads).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.forum_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conversation${totalCount > 0 ? ' ($totalCount messages, ${threads.length} threads)' : ''}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                ),
              ],
            ),
            const Divider(height: 24),

            // ── Threaded messages ──
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (threads.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.email_outlined, size: 40,
                          color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'No conversation yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ...visibleThreads.map((thread) {
                final isExpanded = _expandedThreads.contains(thread.key);
                final latest = thread.messages.last;
                final latestBody = renderEmailBody(
                  latest['body_html'] as String? ??
                      latest['html_body'] as String? ??
                      latest['body_text'] as String? ??
                      latest['text_body'] as String? ??
                      latest['body'] as String? ??
                      '',
                );
                final participants = thread.messages
                    .map((m) =>
                        m['from_address'] as String? ??
                        m['sender_email'] as String? ??
                        '')
                    .where((s) => s.isNotEmpty)
                    .toSet()
                    .join(', ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thread header
                      InkWell(
                        onTap: () => setState(() {
                          if (isExpanded) {
                            _expandedThreads.remove(thread.key);
                          } else {
                            _expandedThreads.add(thread.key);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      thread.subject,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (thread.messages.length > 1)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${thread.messages.length}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _fmtTs(thread.latestTimestamp),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              if (participants.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  participants,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (!isExpanded && latestBody.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  latestBody,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Expanded: all messages + inline reply
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < thread.messages.length;
                                  i++)
                                _MessageBubble(
                                  key: ValueKey(
                                    thread.messages[i]['id'] ??
                                        '${thread.key}_$i',
                                  ),
                                  message: thread.messages[i],
                                  initiallyExpanded:
                                      i == thread.messages.length - 1,
                                ),
                            ],
                          ),
                        ),
                        // Per-thread reply composer
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: _ThreadReplyComposer(
                            recordId: widget.recordId,
                            onSent: () {
                              setState(() => _loading = true);
                              _load();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              // Load more
              if (threads.length > _visibleThreads)
                Center(
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _visibleThreads += 20),
                    child: Text(
                        'Show more (${threads.length - _visibleThreads} remaining)'),
                  ),
                ),
            ],

          ],
        ),
      ),
    );
  }
}

class _EmailThread {
  const _EmailThread({
    required this.key,
    required this.subject,
    required this.messages,
    required this.latestTimestamp,
  });

  final String key;
  final String subject;
  final List<Map<String, dynamic>> messages;
  final String latestTimestamp;
}

/// Inline reply composer shown at the bottom of each expanded thread.
class _ThreadReplyComposer extends StatefulWidget {
  const _ThreadReplyComposer({
    required this.recordId,
    required this.onSent,
  });

  final String recordId;
  final VoidCallback onSent;

  @override
  State<_ThreadReplyComposer> createState() => _ThreadReplyComposerState();
}

class _ThreadReplyComposerState extends State<_ThreadReplyComposer> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty) return;

    setState(() => _sending = true);
    try {
      await GetIt.instance<RecordRemoteDataSource>()
          .replyToRecord(widget.recordId, body);
      _ctrl.clear();
      if (mounted) {
        setState(() {
          _sending = false;
          _sent = true;
        });
        widget.onSent();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reply')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Reply',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: 'Type your reply...',
              border: const OutlineInputBorder(),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surface,
            ),
            maxLines: 5,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            enabled: !_sending,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_sending)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sending...',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colorScheme.primary),
                    ),
                  ],
                )
              else if (_sent)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Sent',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colorScheme.primary),
                    ),
                  ],
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gmail-style message bubble: collapsed header → tap to expand body.
class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    this.initiallyExpanded = false,
    super.key,
  });

  final Map<String, dynamic> message;
  final bool initiallyExpanded;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  late bool _expanded = widget.initiallyExpanded;
  String? _plainPreviewCache;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final message = widget.message;

    final direction = (message['direction'] as String? ?? '').toLowerCase();
    final isOutbound = direction == 'outbound' || direction == 'out' ||
        direction == 'sent' || direction == 'reply';

    final subject = message['subject'] as String?;
    final body = message['body_html'] as String? ??
        message['html_body'] as String? ??
        message['body_text'] as String? ??
        message['text_body'] as String? ??
        message['body'] as String? ??
        message['content'] as String? ??
        '';
    final plainPreview = _plainPreviewCache ??= renderEmailBody(body);
    final fromAddress = message['from_address'] as String? ??
        message['sender_email'] as String? ??
        message['from'] as String? ??
        '';
    final toAddress = message['to_address'] as String? ??
        message['to'] as String? ??
        '';
    final timestamp = message['created_at'] as String? ??
        message['sent_at'] as String? ??
        message['date'] as String? ??
        '';

    final cc =
        message['cc'] as String? ?? message['cc_addresses'] as String? ?? '';
    final bcc =
        message['bcc'] as String? ?? message['bcc_addresses'] as String? ?? '';
    final replyTo = message['reply_to'] as String? ?? '';
    final messageId = message['message_id'] as String? ?? '';
    final attachments = message['attachments'] as List<dynamic>? ?? [];

    // Sender display name (strip <email> if present)
    final senderDisplay = fromAddress.contains('<')
        ? fromAddress.substring(0, fromAddress.indexOf('<')).trim()
        : fromAddress.split('@').first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _expanded
                ? (isOutbound
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : colorScheme.surfaceContainerHighest)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: _expanded
                ? Border.all(
                    color: isOutbound
                        ? colorScheme.primary.withValues(alpha: 0.2)
                        : colorScheme.outlineVariant,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row (always visible, Gmail-style) ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isOutbound
                          ? colorScheme.primary
                          : colorScheme.tertiaryContainer,
                      child: Text(
                        senderDisplay.isNotEmpty
                            ? senderDisplay[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isOutbound
                              ? colorScheme.onPrimary
                              : colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Sender + preview
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isOutbound ? 'You' : senderDisplay,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (attachments.isNotEmpty) ...[
                                Icon(Icons.attach_file,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _fmtTs(timestamp),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (!_expanded && plainPreview.isNotEmpty)
                            Text(
                              plainPreview,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),

              // ── Expanded: full inline email ──
              if (_expanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address headers
                      if (fromAddress.isNotEmpty)
                        _addressRow(theme, 'From', fromAddress),
                      if (toAddress.isNotEmpty)
                        _addressRow(theme, 'To', toAddress),
                      if (cc.isNotEmpty) _addressRow(theme, 'CC', cc),
                      if (bcc.isNotEmpty) _addressRow(theme, 'BCC', bcc),
                      if (subject != null && subject!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subject!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      // Full email body
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: HtmlEmailView(
                            body: body,
                            showToggle: true,
                            textStyle:
                                theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],

                      // Attachments
                      if (attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: attachments.map((a) {
                            final name = a is Map
                                ? (a['filename'] as String? ?? 'File')
                                : a.toString();
                            final size =
                                a is Map ? (a['size'] as int?) : null;
                            final sizeLabel = size != null
                                ? ' (${(size / 1024).toStringAsFixed(1)} KB)'
                                : '';
                            return Chip(
                              avatar:
                                  const Icon(Icons.attach_file, size: 14),
                              label: Text('$name$sizeLabel'),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _addressRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
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
  bool _uploading = false;

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

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      // 25 MB server limit.
      const maxBytes = 25 * 1024 * 1024;
      if (file.size > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File too large (${(file.size / 1024 / 1024).toStringAsFixed(1)} MB). Maximum is 25 MB.',
              ),
            ),
          );
        }
        return;
      }

      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File data unavailable')),
          );
        }
        return;
      }
      if (!mounted) return;

      setState(() => _uploading = true);
      final formData = FormData.fromMap({
        'parent_type': 'record',
        'parent_id': widget.recordId,
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });

      await GetIt.instance<Dio>().post<void>(
        '/api/files/upload',
        data: formData,
      );

      if (mounted) {
        setState(() => _uploading = false);
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${file.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fileCount = _files?.length ?? 0;

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
                    'Files${fileCount > 0 ? ' ($fileCount)' : ''}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_uploading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  tooltip: 'Upload file',
                  onPressed: _uploading ? null : _uploadFile,
                ),
              ],
            ),
            const Divider(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_files == null || _files!.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No files attached',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FutureBuilder(
      future: GetIt.instance<TimelineRepository>().getTimeline(
        entityType: 'records',
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

class _RecordDetailsCard extends StatefulWidget {
  const _RecordDetailsCard({
    required this.record,
    required this.stage,
    required this.pipelineName,
    required this.onShowAddTagDialog,
  });

  final PipelineRecord record;
  final Stage? stage;
  final String? pipelineName;
  final VoidCallback onShowAddTagDialog;

  @override
  State<_RecordDetailsCard> createState() => _RecordDetailsCardState();
}

class _RecordDetailsCardState extends State<_RecordDetailsCard> {
  bool _editingTitle = false;
  bool _editingContact = false;
  bool _editingCompany = false;
  bool _editingOwner = false;
  bool _editingStage = false;
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.record.title);
  }

  @override
  void didUpdateWidget(covariant _RecordDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.title != widget.record.title && !_editingTitle) {
      _titleCtrl.text = widget.record.title;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final newTitle = _titleCtrl.text.trim();
    if (newTitle.isEmpty || newTitle == widget.record.title) {
      setState(() => _editingTitle = false);
      return;
    }
    context.read<RecordBloc>().add(
          RecordUpdateRequested(
            id: widget.record.id,
            title: newTitle,
          ),
        );
    setState(() => _editingTitle = false);
  }

  void _updateField({
    String? contactId,
    String? companyId,
    String? ownerId,
  }) {
    context.read<RecordBloc>().add(
          RecordUpdateRequested(
            id: widget.record.id,
            title: widget.record.title,
            contactId: contactId,
            companyId: companyId,
            ownerId: ownerId,
          ),
        );
  }

  Future<List<Map<String, dynamic>>> _searchContacts(String query) async {
    final response = await GetIt.instance<ContactRemoteDataSource>()
        .getContacts(page: 1, perPage: 10);
    final q = query.toLowerCase();
    return response.items
        .where((c) {
          final name = '${c.firstName} ${c.lastName}'.toLowerCase();
          return name.contains(q) || c.email.toLowerCase().contains(q);
        })
        .map((c) => {
              'id': c.id,
              'name': '${c.firstName} ${c.lastName}'.trim(),
              'email': c.email,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> _searchCompanies(String query) async {
    final companies =
        await GetIt.instance<CompanyRemoteDataSource>().getCompanies();
    return companies
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .map((c) => {'id': c.id, 'name': c.name})
        .toList();
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String query) async {
    final dio = GetIt.instance<Dio>();
    final response =
        await dio.get<Map<String, dynamic>>('/api/users');
    final list = response.data?['data'] as List<dynamic>? ?? [];
    final q = query.toLowerCase();
    return list
        .cast<Map<String, dynamic>>()
        .where((u) {
          final name = '${u['name'] ?? ''}'.toLowerCase();
          final email = '${u['email'] ?? ''}'.toLowerCase();
          return name.contains(q) || email.contains(q);
        })
        .map((u) => {
              'id': u['id'] as String? ?? '',
              'name': u['name'] as String? ?? u['email'] as String? ?? '',
              'email': u['email'] as String? ?? '',
            })
        .toList();
  }

  Widget _inlineSearchField({
    required IconData icon,
    required String label,
    required Future<List<Map<String, dynamic>>> Function(String) searchFn,
    required void Function(Map<String, dynamic>) onSelected,
    required VoidCallback onCancel,
    String Function(Map<String, dynamic>)? itemSubtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(icon, size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SearchOrCreateField<Map<String, dynamic>>(
              label: 'Search $label...',
              onSearch: searchFn,
              itemLabel: (c) => c['name'] as String? ?? '',
              itemSubtitle: itemSubtitle,
              onSelected: onSelected,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }

  Widget _inlineStageDropdown(
    BuildContext context,
    PipelineRecord record,
    ColorScheme colorScheme,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final pipelineState = context.read<PipelineBloc>().state;
    final stages = pipelineState is PipelineLoaded
        ? (pipelineState.kanbanStages ?? <Stage>[])
        : <Stage>[];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 20,
              color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: record.stageId,
              decoration: InputDecoration(
                labelText: l10n.stage,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              items: stages
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id != null && id != record.stageId) {
                  context.read<RecordBloc>().add(
                        RecordMoveRequested(
                          recordId: record.id,
                          toStageId: id,
                        ),
                      );
                }
                setState(() => _editingStage = false);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _editingStage = false),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final record = widget.record;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.details,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 24),

            // ── Title (inline editable) ──
            if (_editingTitle)
              Row(
                children: [
                  Icon(Icons.title, size: 20,
                      color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _titleCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _saveTitle(),
                      onTapOutside: (_) => _saveTitle(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, size: 18),
                    onPressed: _saveTitle,
                  ),
                ],
              )
            else
              GestureDetector(
                onDoubleTap: () => setState(() => _editingTitle = true),
                child: _DetailRow(
                  icon: Icons.title,
                  label: l10n.title,
                  value: record.title,
                ),
              ),

            // ── Pipeline (read-only) ──
            _DetailRow(
              icon: Icons.view_kanban_outlined,
              label: l10n.pipeline,
              value: widget.pipelineName ?? '—',
            ),

            // ── Stage (inline dropdown on double-tap) ──
            if (_editingStage)
              _inlineStageDropdown(context, record, colorScheme, theme, l10n)
            else
              GestureDetector(
                onDoubleTap: () => setState(() => _editingStage = true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 20,
                          color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: Text(
                          l10n.stage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.stage?.name ?? '—',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Icon(Icons.edit_outlined, size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),

            // ── Contact (inline search on double-tap) ──
            if (_editingContact)
              _inlineSearchField(
                icon: Icons.person_outline,
                label: l10n.contact,
                searchFn: _searchContacts,
                onSelected: (c) {
                  _updateField(contactId: c['id'] as String?);
                  setState(() => _editingContact = false);
                },
                onCancel: () => setState(() => _editingContact = false),
                itemSubtitle: (c) => c['email'] as String? ?? '',
              )
            else
              GestureDetector(
                onDoubleTap: () => setState(() => _editingContact = true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20,
                          color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: Text(
                          l10n.contact,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: record.contactId != null
                            ? ResolvedName(
                                id: record.contactId,
                                type: 'contact',
                                style: theme.textTheme.bodyMedium,
                              )
                            : Text(
                                '+ Add contact',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                      ),
                      Icon(Icons.edit_outlined, size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),

            // ── Company (inline search on double-tap) ──
            if (_editingCompany)
              _inlineSearchField(
                icon: Icons.business_outlined,
                label: 'Company',
                searchFn: _searchCompanies,
                onSelected: (c) {
                  _updateField(companyId: c['id'] as String?);
                  setState(() => _editingCompany = false);
                },
                onCancel: () => setState(() => _editingCompany = false),
              )
            else
              GestureDetector(
                onDoubleTap: () => setState(() => _editingCompany = true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.business_outlined, size: 20,
                          color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Company',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: record.companyId != null
                            ? ResolvedName(
                                id: record.companyId,
                                type: 'company',
                                style: theme.textTheme.bodyMedium,
                              )
                            : Text(
                                '+ Add company',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                      ),
                      Icon(Icons.edit_outlined, size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),

            // ── Owner (inline search on double-tap) ──
            if (_editingOwner)
              _inlineSearchField(
                icon: Icons.assignment_ind_outlined,
                label: l10n.owner,
                searchFn: _searchUsers,
                onSelected: (u) {
                  _updateField(ownerId: u['id'] as String?);
                  setState(() => _editingOwner = false);
                },
                onCancel: () => setState(() => _editingOwner = false),
                itemSubtitle: (u) => u['email'] as String? ?? '',
              )
            else
              GestureDetector(
                onDoubleTap: () => setState(() => _editingOwner = true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_ind_outlined, size: 20,
                          color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: Text(
                          l10n.owner,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: record.ownerId != null
                            ? ResolvedName(
                                id: record.ownerId,
                                type: 'user',
                                style: theme.textTheme.bodyMedium,
                              )
                            : Text(
                                '+ Assign owner',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                      ),
                      Icon(Icons.edit_outlined, size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),

            // ── Source (read-only) ──
            _DetailRow(
              icon: Icons.source_outlined,
              label: l10n.source,
              value: record.source.name,
            ),

            // ── Sender Email (shown for email-sourced records) ──
            if (record.source == RecordSource.email &&
                record.senderEmail != null &&
                record.senderEmail!.isNotEmpty)
              _DetailRow(
                icon: Icons.email_outlined,
                label: 'From',
                value: record.senderEmail!,
              ),

            // ── Tags (interactive) ──
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
                    children: [
                      ...record.tags.map(
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
                          deleteIcon: Icon(
                            Icons.close,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onDeleted: () {
                            final updatedTags =
                                List<String>.from(record.tags)..remove(tag);
                            context.read<RecordBloc>().add(
                                  RecordUpdateRequested(
                                    id: record.id,
                                    title: record.title,
                                    tags: updatedTags,
                                  ),
                                );
                          },
                        ),
                      ),
                      ActionChip(
                        avatar: Icon(
                          Icons.add,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        label: Text(
                          'Add tag',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        side: BorderSide(
                          color:
                              colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        onPressed: widget.onShowAddTagDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Created/Updated (read-only) ──
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.created,
              value: _formatDate(record.createdAt),
            ),
            _DetailRow(
              icon: Icons.update_outlined,
              label: l10n.updated,
              value: _formatDate(record.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
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
        ],
      ),
    );
  }
}
