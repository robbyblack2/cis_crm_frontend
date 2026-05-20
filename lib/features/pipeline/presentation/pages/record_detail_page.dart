import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/utils/html_utils.dart';
import 'package:cis_crm/core/utils/name_resolver.dart';
import 'package:cis_crm/core/widgets/activities_section.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
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
                        _DetailRow(
                          icon: Icons.view_kanban_outlined,
                          label: AppLocalizations.of(context)!.pipeline,
                          value: pipelineName ?? '—',
                        ),
                        _DetailRow(
                          icon: Icons.flag_outlined,
                          label: AppLocalizations.of(context)!.stage,
                          value: stage?.name ?? '—',
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Use the Linked Contacts tab to manage contacts',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, size: 20, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 12),
                                SizedBox(width: 80, child: Text(AppLocalizations.of(context)!.contact, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                                Expanded(
                                  child: record.contactId != null
                                      ? ResolvedName(id: record.contactId, type: 'contact', style: theme.textTheme.bodyMedium)
                                      : Text('+ Add contact', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontStyle: FontStyle.italic)),
                                ),
                                Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Company linking available via record edit',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.business_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 12),
                                SizedBox(width: 80, child: Text('Company', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                                Expanded(
                                  child: record.companyId != null
                                      ? ResolvedName(id: record.companyId, type: 'company', style: theme.textTheme.bodyMedium)
                                      : Text('+ Add company', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontStyle: FontStyle.italic)),
                                ),
                                Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            try {
                              await GetIt.instance<RecordRemoteDataSource>()
                                  .claimRecord(record.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Record claimed')),
                                );
                                context.read<RecordBloc>().add(const RecordLoadRequested());
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to claim')),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.assignment_ind_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 12),
                                SizedBox(width: 80, child: Text(AppLocalizations.of(context)!.owner, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                                Expanded(
                                  child: record.ownerId != null
                                      ? ResolvedName(id: record.ownerId, type: 'user', style: theme.textTheme.bodyMedium)
                                      : Text('+ Assign owner', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontStyle: FontStyle.italic)),
                                ),
                                Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                        _DetailRow(
                          icon: Icons.source_outlined,
                          label: AppLocalizations.of(context)!.source,
                          value: record.source.name,
                        ),
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
                                      labelStyle:
                                          theme.textTheme.labelSmall,
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
                                        color:
                                            colorScheme.onSurfaceVariant,
                                      ),
                                      onDeleted: () {
                                        final updatedTags =
                                            List<String>.from(record.tags)
                                              ..remove(tag);
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
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.3),
                                    ),
                                    onPressed: () =>
                                        _showAddTagDialog(
                                      context,
                                      record,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
            // Add note field
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
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
                (note) => _NoteItem(
                  body: note['body'] as String? ?? '',
                  timestamp: _relativeTime(note['created_at'] as String?),
                  author: note['created_by'] as String?,
                ),
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
    this.author,
  });

  final String body;
  final String timestamp;
  final String? author;

  @override
  State<_NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<_NoteItem> {
  bool _expanded = false;

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
            // Header: avatar + author + timestamp
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    widget.author != null && widget.author!.isNotEmpty
                        ? widget.author![0].toUpperCase()
                        : '?',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.timestamp,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
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

  void _showLinkDialog() {
    String? selectedContactId;
    String? selectedContactName;
    var role = 'user';
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool searching = false;

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

                // Selected contact chip
                if (selectedContactId != null) ...[
                  Chip(
                    avatar: CircleAvatar(
                      child: Text(
                        selectedContactName != null &&
                                selectedContactName!.isNotEmpty
                            ? selectedContactName![0].toUpperCase()
                            : '?',
                      ),
                    ),
                    label: Text(selectedContactName ?? selectedContactId!),
                    onDeleted: () => setSheetState(() {
                      selectedContactId = null;
                      selectedContactName = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],

                // Search field
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Search contacts by name or email',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: searching
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
                  onChanged: (query) async {
                    if (query.length < 2) {
                      setSheetState(() => searchResults = []);
                      return;
                    }
                    setSheetState(() => searching = true);
                    try {
                      final response =
                          await GetIt.instance<ContactRemoteDataSource>()
                              .getContacts(page: 1, perPage: 10);
                      final q = query.toLowerCase();
                      final filtered = response.items
                          .where((c) {
                            final name =
                                '${c.firstName} ${c.lastName}'.toLowerCase();
                            return name.contains(q) ||
                                c.email.toLowerCase().contains(q);
                          })
                          .map((c) => {
                                'id': c.id,
                                'name':
                                    '${c.firstName} ${c.lastName}'.trim(),
                                'email': c.email,
                              })
                          .toList();
                      setSheetState(() {
                        searchResults = filtered;
                        searching = false;
                      });
                    } catch (_) {
                      setSheetState(() {
                        searchResults = [];
                        searching = false;
                      });
                    }
                  },
                ),

                // Search results
                if (searchCtrl.text.length >= 2) ...[
                  const SizedBox(height: 8),
                  if (searchResults.isNotEmpty)
                    ...searchResults.map(
                      (r) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          child: Text(
                            (r['name'] as String).isNotEmpty
                                ? (r['name'] as String)[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        title: Text(r['name'] as String),
                        subtitle: Text(
                          r['email'] as String,
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                        onTap: () => setSheetState(() {
                          selectedContactId = r['id'] as String;
                          selectedContactName = r['name'] as String;
                          searchCtrl.clear();
                          searchResults = [];
                        }),
                      ),
                    )
                  else if (!searching)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No contacts found for "${searchCtrl.text}"',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],

                const SizedBox(height: 12),

                // Role selector
                DropdownButtonFormField<String>(
                  value: role,
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
      // Reset status after a brief delay so the user sees "Sent".
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
                    'Conversation',
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

            // ── Message thread ──
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_messages == null || _messages!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 40,
                        color: colorScheme.onSurfaceVariant,
                      ),
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
            else
              ...(_messages!).map(
                (msg) => _MessageBubble(message: msg),
              ),

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
                      // Status indicator
                      if (_sendStatus == _SendStatus.sending)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
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
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_sendStatus == _SendStatus.sent)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sent',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_sendStatus == _SendStatus.failed)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 14,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Failed to send',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
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
    final body = message['body'] as String? ??
        message['text_body'] as String? ??
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
                  // Header: direction icon + from/to + timestamp
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
                          isOutbound
                              ? (toAddress.isNotEmpty
                                  ? 'To: $toAddress'
                                  : 'Outbound reply')
                              : (fromAddress.isNotEmpty
                                  ? 'From: $fromAddress'
                                  : 'Inbound'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isOutbound
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
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

                  // Subject line
                  if (subject != null && subject.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subject,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOutbound
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],

                  // Email body
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    SelectableText(
                      renderEmailBody(body),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isOutbound
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
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
            body: ListView(
              controller: scrollCtrl,
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
                        if (fromAddress.isNotEmpty)
                          _headerRow(theme, 'From', fromAddress),
                        if (toAddress.isNotEmpty)
                          _headerRow(theme, 'To', toAddress),
                        if (cc.isNotEmpty) _headerRow(theme, 'CC', cc),
                        if (bcc.isNotEmpty) _headerRow(theme, 'BCC', bcc),
                        if (replyTo.isNotEmpty)
                          _headerRow(theme, 'Reply-To', replyTo),
                        if (subject != null && subject.isNotEmpty)
                          _headerRow(theme, 'Subject', subject),
                        if (timestamp.isNotEmpty)
                          _headerRow(theme, 'Date', _fmtTs(timestamp)),
                        if (messageId.isNotEmpty)
                          _headerRow(theme, 'Message-ID', messageId),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Body
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Body',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(height: 24),
                        SelectableText(
                          renderEmailBody(body),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                // Attachments
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachments (${attachments.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Divider(height: 24),
                          ...attachments.map((a) {
                            final name = a is Map
                                ? (a['filename'] as String? ?? 'File')
                                : a.toString();
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.attach_file),
                              title: Text(name),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
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
        '/api/files',
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
