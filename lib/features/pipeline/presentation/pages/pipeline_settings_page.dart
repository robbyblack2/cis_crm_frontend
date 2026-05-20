import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/pipeline/data/datasources/pipeline_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
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

  static const _stageColors = <({String hex, String name})>[
    (hex: '#EF4444', name: 'Red'),
    (hex: '#F97316', name: 'Orange'),
    (hex: '#EAB308', name: 'Yellow'),
    (hex: '#22C55E', name: 'Green'),
    (hex: '#10B981', name: 'Emerald'),
    (hex: '#06B6D4', name: 'Cyan'),
    (hex: '#3B82F6', name: 'Blue'),
    (hex: '#6366F1', name: 'Indigo'),
    (hex: '#A855F7', name: 'Purple'),
    (hex: '#EC4899', name: 'Pink'),
    (hex: '#64748B', name: 'Slate'),
    (hex: '#78716C', name: 'Stone'),
  ];

  void _showAddStageDialog() {
    final nameCtrl = TextEditingController();
    var selectedColor = '#3B82F6';
    var stageType = 'normal';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add Stage',
                    style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Text('Color',
                    style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 8),
                _ColorGrid(
                  colors: _stageColors,
                  selectedHex: selectedColor,
                  onSelected: (hex) =>
                      setSheetState(() => selectedColor = hex),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: stageType,
                  decoration: const InputDecoration(
                    labelText: 'Stage type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['normal', 'won', 'lost']
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => stageType = v);
                  },
                ),
                const SizedBox(height: 16),
                // Live preview
                if (nameCtrl.text.trim().isNotEmpty)
                  Row(
                    children: [
                      Text('Preview: ',
                          style: Theme.of(ctx).textTheme.labelMedium),
                      Chip(
                        label: Text(nameCtrl.text.trim()),
                        backgroundColor:
                            _parseColor(selectedColor).withValues(alpha: 0.15),
                        side: BorderSide(
                          color:
                              _parseColor(selectedColor).withValues(alpha: 0.4),
                        ),
                        labelStyle: TextStyle(
                          color: _parseColor(selectedColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
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
                        color: selectedColor,
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
        ),
      ),
    );
  }

  void _showEditDialog(Stage stage) {
    final nameCtrl = TextEditingController(text: stage.name);
    var selectedColor = stage.color;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit Stage',
                    style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Text('Color',
                    style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 8),
                _ColorGrid(
                  colors: _stageColors,
                  selectedHex: selectedColor,
                  onSelected: (hex) =>
                      setSheetState(() => selectedColor = hex),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Preview: ',
                        style: Theme.of(ctx).textTheme.labelMedium),
                    Chip(
                      label: Text(nameCtrl.text.trim().isNotEmpty
                          ? nameCtrl.text.trim()
                          : stage.name),
                      backgroundColor:
                          _parseColor(selectedColor).withValues(alpha: 0.15),
                      side: BorderSide(
                        color:
                            _parseColor(selectedColor).withValues(alpha: 0.4),
                      ),
                      labelStyle: TextStyle(
                        color: _parseColor(selectedColor),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await getIt<PipelineRemoteDataSource>().updateStage(
                        id: stage.id,
                        name: nameCtrl.text.trim(),
                        position: stage.position,
                        color: selectedColor,
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
          ),
        ),
      ),
    );
  }

  Future<void> _deletePipeline(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${widget.pipelineName}"?'),
        content: const Text(
          'This will permanently delete this pipeline and all its stages. '
          'Records must be moved to another pipeline first.',
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
      await getIt<Dio>().delete<void>(
        '/api/pipelines/${widget.pipelineId}',
      );
      if (mounted) {
        Navigator.of(context).pop(); // Close settings page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pipeline deleted')),
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Delete pipeline',
            onPressed: () => _deletePipeline(context),
          ),
        ],
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
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to reorder stage: $e'),
                            ),
                          );
                        }
                        break;
                      }
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

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({
    required this.colors,
    required this.selectedHex,
    required this.onSelected,
  });

  final List<({String hex, String name})> colors;
  final String selectedHex;
  final ValueChanged<String> onSelected;

  Color _parse(String hex) {
    if (hex.startsWith('#') && hex.length == 7) {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final selectedName = colors
        .where((c) => c.hex == selectedHex)
        .map((c) => c.name)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((c) {
            final color = _parse(c.hex);
            final isSelected = c.hex == selectedHex;
            return GestureDetector(
              onTap: () => onSelected(c.hex),
              child: Tooltip(
                message: c.name,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2.5,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedName != null) ...[
          const SizedBox(height: 8),
          Text(
            '$selectedName ($selectedHex)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
