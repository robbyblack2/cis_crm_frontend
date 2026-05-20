import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/pages/pipeline_builder_page.dart';
import 'package:cis_crm/features/pipeline/presentation/pages/pipeline_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';

class PipelineManagementPage extends StatelessWidget {
  const PipelineManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Ensure pipelines are loaded when this page is opened
    final bloc = context.read<PipelineBloc>();
    if (bloc.state is PipelineInitial) {
      bloc.add(const PipelineLoadRequested());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pipelines'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PipelineBloc>(),
                        child: const PipelineBuilderPage(),
                      ),
                    ),
                  ),
        icon: const Icon(Icons.add),
        label: const Text('New Pipeline'),
      ),
      body: BlocBuilder<PipelineBloc, PipelineState>(
        builder: (context, state) {
          if (state is PipelineLoading || state is PipelineInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PipelineError) {
            return Center(child: Text(state.message));
          }
          if (state is! PipelineLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final pipelines = state.pipelines;

          if (pipelines.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_kanban_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pipelines yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PipelineBloc>(),
                        child: const PipelineBuilderPage(),
                      ),
                    ),
                  ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Pipeline'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pipelines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final pipeline = pipelines[index];
              return _PipelineCard(
                pipeline: pipeline,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PipelineSettingsPage(
                      pipelineId: pipeline.id,
                      pipelineName: pipeline.name,
                    ),
                  ),
                ),
                onRename: () => _showRenameDialog(context, pipeline),
                onToggleActive: () {
                  context.read<PipelineBloc>().add(
                        PipelineUpdateRequested(
                          id: pipeline.id,
                          name: pipeline.name,
                          isActive: !pipeline.isActive,
                        ),
                      );
                },
                onDelete: () => _showDeleteDialog(context, pipeline, l10n),
              );
            },
          );
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Pipeline pipeline) {
    final nameCtrl = TextEditingController(text: pipeline.name);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Rename Pipeline',
                style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Pipeline name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                context.read<PipelineBloc>().add(
                      PipelineUpdateRequested(
                        id: pipeline.id,
                        name: name,
                        isActive: pipeline.isActive,
                      ),
                    );
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                context.read<PipelineBloc>().add(
                      PipelineUpdateRequested(
                        id: pipeline.id,
                        name: name,
                        isActive: pipeline.isActive,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(ctx)!.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    Pipeline pipeline,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${pipeline.name}"?'),
        content: const Text(
          'This will permanently delete this pipeline and all its stages. '
          'Records must be moved to another pipeline first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<PipelineBloc>().add(
                    PipelineDeleteRequested(id: pipeline.id),
                  );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({
    required this.pipeline,
    required this.onTap,
    required this.onRename,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Pipeline pipeline;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSales = pipeline.pipelineType == PipelineType.sales;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: name + type badge ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pipeline.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: pipeline.isActive
                            ? null
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSales
                          ? colorScheme.primaryContainer
                          : colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSales ? Icons.attach_money : Icons.support_agent,
                          size: 14,
                          color: isSales
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSales ? 'Sales' : 'Support',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSales
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Status + actions row ──
              Row(
                children: [
                  // Active status
                  Icon(
                    pipeline.isActive
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                    size: 16,
                    color: pipeline.isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pipeline.isActive ? 'Active' : 'Inactive',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: pipeline.isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Rename
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Rename',
                    onPressed: onRename,
                    visualDensity: VisualDensity.compact,
                  ),
                  // Toggle active
                  IconButton(
                    icon: Icon(
                      pipeline.isActive
                          ? Icons.pause_outlined
                          : Icons.play_arrow_outlined,
                      size: 20,
                    ),
                    tooltip:
                        pipeline.isActive ? 'Deactivate' : 'Activate',
                    onPressed: onToggleActive,
                    visualDensity: VisualDensity.compact,
                  ),
                  // Delete
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
