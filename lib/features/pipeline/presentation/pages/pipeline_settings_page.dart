import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/pipeline/data/datasources/pipeline_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class PipelineSettingsPage extends StatefulWidget {
  const PipelineSettingsPage({
    required this.pipelineId,
    required this.pipelineName,
    super.key,
  });

  final String pipelineId;
  final String pipelineName;

  @override
  State<PipelineSettingsPage> createState() => _PipelineSettingsPageState();
}

class _PipelineSettingsPageState extends State<PipelineSettingsPage> {
  List<Stage>? _stages;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStages();
  }

  Future<void> _loadStages() async {
    setState(() => _loading = true);
    try {
      final stages = await getIt<PipelineRemoteDataSource>()
          .getStages(widget.pipelineId);
      if (mounted) {
        setState(() {
          _stages = stages..sort((a, b) => a.position.compareTo(b.position));
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _stages = []; _loading = false; });
    }
  }

  void _showAddStageDialog() {
    final nameCtrl = TextEditingController();
    final colorCtrl = TextEditingController(text: '#3B82F6');
    var stageType = 'normal';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Stage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: colorCtrl,
                decoration:
                    const InputDecoration(labelText: 'Color (hex)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: stageType,
                decoration:
                    const InputDecoration(labelText: 'Stage type'),
                items: ['normal', 'won', 'lost']
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => stageType = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx)!.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await getIt<PipelineRemoteDataSource>().createStage(
                    pipelineId: widget.pipelineId,
                    name: name,
                    position: (_stages?.length ?? 0),
                    color: colorCtrl.text.trim(),
                    stageType: stageType,
                  );
                  await _loadStages();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
              child: Text(AppLocalizations.of(ctx)!.create),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Stage stage) {
    final nameCtrl = TextEditingController(text: stage.name);
    final colorCtrl = TextEditingController(text: stage.color);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Stage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: colorCtrl,
              decoration:
                  const InputDecoration(labelText: 'Color (hex)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await getIt<PipelineRemoteDataSource>().updateStage(
                  id: stage.id,
                  name: nameCtrl.text.trim(),
                  position: stage.position,
                  color: colorCtrl.text.trim(),
                );
                await _loadStages();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(ctx)!.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStage(Stage stage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${stage.name}"?'),
        content: const Text(
          'Records in this stage will need to be moved first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(ctx)!.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await getIt<PipelineRemoteDataSource>().deleteStage(stage.id);
      await _loadStages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Color _parseColor(String hex) {
    if (hex.startsWith('#')) {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pipelineName} — Stages'),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'pipeline_settings_fab',
        onPressed: _showAddStageDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stages == null || _stages!.isEmpty
              ? Center(
                  child: Text(
                    'No stages configured',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stages!.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final stage = _stages!.removeAt(oldIndex);
                    _stages!.insert(newIndex, stage);
                    setState(() {});
                    // Update positions on server
                    for (var i = 0; i < _stages!.length; i++) {
                      try {
                        await getIt<PipelineRemoteDataSource>()
                            .updateStage(
                          id: _stages![i].id,
                          name: _stages![i].name,
                          position: i,
                        );
                      } catch (_) {}
                    }
                  },
                  itemBuilder: (context, index) {
                    final stage = _stages![index];
                    final color = _parseColor(stage.color);
                    return Card(
                      key: ValueKey(stage.id),
                      child: ListTile(
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(stage.name),
                        subtitle: Text(
                          'Position: ${stage.position} · '
                          '${stage.stageType}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showEditDialog(stage),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outlined,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () => _deleteStage(stage),
                            ),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
