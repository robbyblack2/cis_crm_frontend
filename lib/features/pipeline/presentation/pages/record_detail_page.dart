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
    // Default to Conversation tab (index 0) for support pipelines
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(icon: Icon(Icons.forum_outlined, size: 18), text: 'Conversation'),
            Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Details'),
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
          // ── Tab 1: Conversation ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _ConversationSection(recordId: record.id),
          ),

          // ── Tab 2: Details ──
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
              ],
            ),
          ),

          // ── Tab 3: Activity (Notes + Timeline) ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _NotesSection(recordId: record.id),
                const SizedBox(height: 16),
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
                        hintText: 'Add a note... (Enter to send)',
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

class _ConversationSection extends StatefulWidget {
  const _ConversationSection({required this.recordId});
  final String recordId;

  @override
  State<_ConversationSection> createState() => _ConversationSectionState();
}

enum _SendStatus { idle, sending, sent, failed }

class _ConversationSectionState extends State<_ConversationSection> {
  List<Map<String, dynamic>>? _messages;
  bool _loading = true;
  final _replyCtrl = TextEditingController();
  _SendStatus _sendStatus = _SendStatus.idle;
  int _visibleThreads = 20;
  final Set<String> _expandedThreads = {};

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
      final messages = await GetIt.instance<RecordRemoteDataSource>()
          .getConversation(widget.recordId);
      if (mounted) setState(() { _messages = messages; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _messages = []; _loading = false; });
    }
  }

  /// Group messages into threads by normalized subject.
  List<_EmailThread> _buildThreads() {
    if (_messages == null || _messages!.isEmpty) return [];

    final threadMap = <String, List<Map<String, dynamic>>>{};
    for (final msg in _messages!) {
      final subject = (msg['subject'] as String? ?? '(no subject)')
          .replaceAll(RegExp(r'^(Re|Fwd|Fw):\s*', caseSensitive: false), '')
          .trim();
      final key = subject.toLowerCase();
      threadMap.putIfAbsent(key, () => []).add(msg);
    }

    final threads = threadMap.entries.map((e) {
      // Sort messages within thread oldest first
      e.value.sort((a, b) {
        final aTs = a['created_at'] as String? ?? '';
        final bTs = b['created_at'] as String? ?? '';
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
    return threads;
  }

  Future<void> _sendReply() async {
    final body = _replyCtrl.text.trim();
    if (body.isEmpty) return;

    setState(() => _sendStatus = _SendStatus.sending);
    try {
      await GetIt.instance<RecordRemoteDataSource>()
          .replyToRecord(widget.recordId, body);
      _replyCtrl.clear();
      if (mounted) setState(() => _sendStatus = _SendStatus.sent);
      await _load();
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _sendStatus = _SendStatus.idle);
    } catch (_) {
      if (mounted) {
        setState(() => _sendStatus = _SendStatus.failed);
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
                  latest['text_body'] as String? ??
                      latest['body'] as String? ??
                      latest['html_body'] as String? ??
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
                      // Expanded: all messages
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        ...thread.messages.map(
                          (msg) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: _MessageBubble(message: msg),
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

            const SizedBox(height: 16),

            // ── Reply composer ──
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reply',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _replyCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type your reply...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 5,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: _sendStatus != _SendStatus.sending,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_sendStatus == _SendStatus.sending)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Sending...',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: colorScheme.primary)),
                            ],
                          ),
                        )
                      else if (_sendStatus == _SendStatus.sent)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 14,
                                  color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('Sent',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: colorScheme.primary)),
                            ],
                          ),
                        )
                      else if (_sendStatus == _SendStatus.failed)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 14,
                                  color: colorScheme.error),
                              const SizedBox(width: 4),
                              Text('Failed to send',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: colorScheme.error)),
                            ],
                          ),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _sendStatus == _SendStatus.sending
                            ? null
                            : _sendReply,
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Send Reply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

/// A single message bubble in the conversation thread.
/// Inbound messages (from customer) align left, outbound (replies) align right.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final direction = (message['direction'] as String? ?? '').toLowerCase();
    final isOutbound = direction == 'outbound' || direction == 'out' ||
        direction == 'sent' || direction == 'reply';

    final subject = message['subject'] as String?;
    final body = message['text_body'] as String? ??
        message['body'] as String? ??
        message['html_body'] as String? ??
        message['content'] as String? ??
        '';
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

    final cc = message['cc'] as String? ?? message['cc_addresses'] as String? ?? '';
    final bcc = message['bcc'] as String? ?? message['bcc_addresses'] as String? ?? '';
    final replyTo = message['reply_to'] as String? ?? '';
    final messageId = message['message_id'] as String? ?? '';
    final attachments = message['attachments'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isOutbound ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: InkWell(
            onTap: () => _showFullEmail(
              context,
              subject: subject,
              body: body,
              fromAddress: fromAddress,
              toAddress: toAddress,
              cc: cc,
              bcc: bcc,
              replyTo: replyTo,
              messageId: messageId,
              timestamp: timestamp,
              isOutbound: isOutbound,
              attachments: attachments,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Card(
            color: isOutbound
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isOutbound
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject + timestamp
                  Row(
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
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          subject ?? '(no subject)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isOutbound
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        Text(
                          _fmtTs(timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // From + To
                  if (fromAddress.isNotEmpty)
                    Text(
                      'From: $fromAddress',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (toAddress.isNotEmpty)
                    Text(
                      'To: $toAddress',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (cc.isNotEmpty)
                    Text(
                      'CC: $cc',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Body preview (plain text, truncated — no HTML rendering for perf)
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      renderEmailBody(body),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOutbound
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Attachment indicator
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.attach_file, size: 14,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Tap to view hint
                  const SizedBox(height: 4),
                  Text(
                    'Tap for full email',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  static void _showFullEmail(
    BuildContext context, {
    String? subject,
    required String body,
    required String fromAddress,
    required String toAddress,
    required String cc,
    required String bcc,
    required String replyTo,
    required String messageId,
    required String timestamp,
    required bool isOutbound,
    required List<dynamic> attachments,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) {
          final theme = Theme.of(ctx);

          return Scaffold(
            appBar: AppBar(
              title: Text(subject ?? 'Email'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            body: _EmailDetailBody(
              scrollCtrl: scrollCtrl,
              subject: subject,
              body: body,
              fromAddress: fromAddress,
              toAddress: toAddress,
              cc: cc,
              bcc: bcc,
              replyTo: replyTo,
              messageId: messageId,
              timestamp: timestamp,
              attachments: attachments,
            ),
          );
        },
      ),
    );
  }
}

class _EmailDetailBody extends StatefulWidget {
  const _EmailDetailBody({
    required this.scrollCtrl,
    this.subject,
    required this.body,
    required this.fromAddress,
    required this.toAddress,
    required this.cc,
    required this.bcc,
    required this.replyTo,
    required this.messageId,
    required this.timestamp,
    required this.attachments,
  });

  final ScrollController scrollCtrl;
  final String? subject;
  final String body;
  final String fromAddress;
  final String toAddress;
  final String cc;
  final String bcc;
  final String replyTo;
  final String messageId;
  final String timestamp;
  final List<dynamic> attachments;

  @override
  State<_EmailDetailBody> createState() => _EmailDetailBodyState();
}

class _EmailDetailBodyState extends State<_EmailDetailBody> {
  bool _showRawSource = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      controller: widget.scrollCtrl,
      padding: const EdgeInsets.all(16),
      children: [
        // Headers card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Headers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 24),
                if (widget.fromAddress.isNotEmpty)
                  _headerRow(theme, 'From', widget.fromAddress),
                if (widget.toAddress.isNotEmpty)
                  _headerRow(theme, 'To', widget.toAddress),
                if (widget.cc.isNotEmpty)
                  _headerRow(theme, 'CC', widget.cc),
                if (widget.bcc.isNotEmpty)
                  _headerRow(theme, 'BCC', widget.bcc),
                if (widget.replyTo.isNotEmpty)
                  _headerRow(theme, 'Reply-To', widget.replyTo),
                if (widget.subject != null && widget.subject!.isNotEmpty)
                  _headerRow(theme, 'Subject', widget.subject!),
                if (widget.timestamp.isNotEmpty)
                  _headerRow(theme, 'Date', _fmtTs(widget.timestamp)),
                if (widget.messageId.isNotEmpty)
                  _headerRow(theme, 'Message-ID', widget.messageId),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Body with view mode toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showRawSource ? 'Raw Source' : 'Body',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (containsHtml(widget.body))
                      TextButton.icon(
                        icon: Icon(
                          _showRawSource ? Icons.article : Icons.code,
                          size: 16,
                        ),
                        label: Text(
                          _showRawSource ? 'Styled view' : 'Raw source',
                        ),
                        onPressed: () =>
                            setState(() => _showRawSource = !_showRawSource),
                      ),
                  ],
                ),
                const Divider(height: 16),
                if (_showRawSource)
                  SelectableText(
                    widget.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  )
                else
                  HtmlEmailView(
                    body: widget.body,
                    showToggle: true,
                    textStyle: theme.textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ),

        // Attachments
        if (widget.attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attachments (${widget.attachments.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 24),
                  ...widget.attachments.map((a) {
                    final name = a is Map
                        ? (a['filename'] as String? ?? 'File')
                        : a.toString();
                    final size = a is Map ? (a['size'] as int?) : null;
                    final sizeStr = size != null
                        ? '${(size / 1024).toStringAsFixed(1)} KB'
                        : '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.attach_file),
                      title: Text(name),
                      subtitle:
                          sizeStr.isNotEmpty ? Text(sizeStr) : null,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Widget _headerRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
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

  void _showContactPicker() {
    showModalBottomSheet<void>(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Contact',
              style: Theme.of(ctx).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SearchOrCreateField<Map<String, dynamic>>(
              label: 'Search contacts...',
              onSearch: _searchContacts,
              itemLabel: (c) => c['name'] as String? ?? '',
              itemSubtitle: (c) => c['email'] as String? ?? '',
              createEntityLabel: 'contact',
              onSelected: (c) {
                Navigator.pop(ctx);
                _updateField(contactId: c['id'] as String?);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCompanyPicker() {
    showModalBottomSheet<void>(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Company',
              style: Theme.of(ctx).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SearchOrCreateField<Map<String, dynamic>>(
              label: 'Search companies...',
              onSearch: _searchCompanies,
              itemLabel: (c) => c['name'] as String? ?? '',
              createEntityLabel: 'company',
              onSelected: (c) {
                Navigator.pop(ctx);
                _updateField(companyId: c['id'] as String?);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showOwnerPicker() {
    showModalBottomSheet<void>(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Assign Owner',
              style: Theme.of(ctx).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SearchOrCreateField<Map<String, dynamic>>(
              label: 'Search team members...',
              onSearch: _searchUsers,
              itemLabel: (u) => u['name'] as String? ?? '',
              itemSubtitle: (u) => u['email'] as String? ?? '',
              onSelected: (u) {
                Navigator.pop(ctx);
                _updateField(ownerId: u['id'] as String?);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showStagePicker() {
    final pipelineState = context.read<PipelineBloc>().state;
    if (pipelineState is! PipelineLoaded) return;
    final stages = pipelineState.kanbanStages;
    if (stages == null || stages.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Move to Stage',
              style: Theme.of(ctx).textTheme.headlineSmall,
            ),
          ),
          ...stages.map(
            (s) => ListTile(
              leading: Icon(
                Icons.flag_outlined,
                color: s.id == widget.record.stageId
                    ? Theme.of(ctx).colorScheme.primary
                    : null,
              ),
              title: Text(s.name),
              selected: s.id == widget.record.stageId,
              onTap: () {
                Navigator.pop(ctx);
                if (s.id != widget.record.stageId) {
                  context.read<RecordBloc>().add(
                        RecordMoveRequested(
                          recordId: widget.record.id,
                          toStageId: s.id,
                        ),
                      );
                }
              },
            ),
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
