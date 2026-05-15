import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        if (recordState is! RecordLoaded) {
          return Scaffold(
            appBar: AppBar(title: const Text('Record')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final record = recordState.records.cast<PipelineRecord?>().firstWhere(
              (r) => r!.id == recordId,
              orElse: () => null,
            );

        if (record == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Record')),
            body: const Center(child: Text('Record not found')),
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
          PopupMenuButton<String>(
            tooltip: 'More actions',
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              PopupMenuItem(
                value: 'move',
                child: ListTile(
                  leading: Icon(Icons.drive_file_move_outlined),
                  title: Text('Move to stage'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outlined),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
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
                      'Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.title,
                      label: 'Title',
                      value: record.title,
                    ),
                    if (pipelineName != null)
                      _DetailRow(
                        icon: Icons.view_kanban_outlined,
                        label: 'Pipeline',
                        value: pipelineName,
                      ),
                    if (stage != null)
                      _DetailRow(
                        icon: Icons.flag_outlined,
                        label: 'Stage',
                        value: stage.name,
                      ),
                    if (record.contactId != null)
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: 'Contact',
                        value: record.contactId!,
                      ),
                    if (record.ownerId != null)
                      _DetailRow(
                        icon: Icons.assignment_ind_outlined,
                        label: 'Owner',
                        value: record.ownerId!,
                      ),
                    _DetailRow(
                      icon: Icons.source_outlined,
                      label: 'Source',
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
                      label: 'Created',
                      value: _formatDate(record.createdAt),
                    ),
                    _DetailRow(
                      icon: Icons.update_outlined,
                      label: 'Updated',
                      value: _formatDate(record.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Timeline placeholder ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.timeline_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Activity timeline coming soon',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
      case 'move':
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${action[0].toUpperCase()}${action.substring(1)} '
              'action not yet implemented',
            ),
          ),
        );
    }
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
