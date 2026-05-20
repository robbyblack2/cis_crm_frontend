import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/pipeline/data/datasources/pipeline_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PipelineBuilderPage extends StatefulWidget {
  const PipelineBuilderPage({super.key});

  @override
  State<PipelineBuilderPage> createState() => _PipelineBuilderPageState();
}

class _PipelineBuilderPageState extends State<PipelineBuilderPage> {
  final _nameCtrl = TextEditingController();
  final _stages = <_StageEntry>[
    _StageEntry(name: 'New', hex: '#3B82F6'),
    _StageEntry(name: 'In Progress', hex: '#F97316'),
    _StageEntry(name: 'Done', hex: '#22C55E', stageType: 'won'),
  ];
  bool _creating = false;

  static const _presetColors = <({String hex, String name})>[
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

  static const _templates = {
    'Sales (6 stages)': [
      _StageTemplate('New Lead', '#3B82F6', 'normal'),
      _StageTemplate('Contacted', '#06B6D4', 'normal'),
      _StageTemplate('Qualified', '#F97316', 'normal'),
      _StageTemplate('Proposal Sent', '#A855F7', 'normal'),
      _StageTemplate('Won', '#22C55E', 'won'),
      _StageTemplate('Lost', '#EF4444', 'lost'),
    ],
    'Support (5 stages)': [
      _StageTemplate('Triage', '#3B82F6', 'normal'),
      _StageTemplate('In Progress', '#F97316', 'normal'),
      _StageTemplate('Waiting on Customer', '#EAB308', 'normal'),
      _StageTemplate('Resolved', '#22C55E', 'won'),
      _StageTemplate('Closed', '#64748B', 'lost'),
    ],
    'Onboarding (4 stages)': [
      _StageTemplate('Signed', '#3B82F6', 'normal'),
      _StageTemplate('Setup', '#F97316', 'normal'),
      _StageTemplate('Training', '#A855F7', 'normal'),
      _StageTemplate('Live', '#22C55E', 'won'),
    ],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pipeline name is required')),
      );
      return;
    }
    if (_stages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one stage')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final pipeline = await getIt<PipelineRemoteDataSource>().createPipeline(
        name: name,
        pipelineType: PipelineType.sales,
      );

      for (var i = 0; i < _stages.length; i++) {
        final stage = _stages[i];
        await getIt<PipelineRemoteDataSource>().createStage(
          pipelineId: pipeline.id,
          name: stage.name,
          position: i,
          color: stage.hex,
          stageType: stage.stageType,
        );
      }

      if (!mounted) return;

      context.read<PipelineBloc>().add(const PipelineLoadRequested());
      context.read<PipelineBloc>().add(
            PipelineKanbanRequested(pipelineId: pipeline.id),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pipeline "$name" created')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  void _addStage() {
    setState(() {
      final colorIdx = _stages.length % _presetColors.length;
      _stages.add(
        _StageEntry(
          name: '',
          hex: _presetColors[colorIdx].hex,
        ),
      );
    });
  }

  void _applyTemplate(List<_StageTemplate> template) {
    setState(() {
      _stages
        ..clear()
        ..addAll(
          template.map(
            (t) => _StageEntry(name: t.name, hex: t.hex, stageType: t.type),
          ),
        );
    });
  }

  void _showColorPicker(int index) {
    showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pick Color',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presetColors.map((c) {
                  final color = _parseHex(c.hex);
                  final isSelected = _stages[index].hex == c.hex;
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, c.hex),
                    child: Tooltip(
                      message: c.name,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurface,
                                  width: 2.5,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    ).then((hex) {
      if (hex != null && mounted) {
        setState(() => _stages[index].hex = hex);
      }
    });
  }

  static Color _parseHex(String hex) {
    if (hex.startsWith('#') && hex.length == 7) {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Pipeline'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'From template',
            icon: const Icon(Icons.dashboard_customize_outlined),
            onSelected: (key) {
              final template = _templates[key];
              if (template != null) _applyTemplate(template);
            },
            itemBuilder: (_) => _templates.keys
                .map((k) => PopupMenuItem(value: k, child: Text(k)))
                .toList(),
          ),
          FilledButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Pipeline Name *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Customer Onboarding',
              ),
              textCapitalization: TextCapitalization.words,
              style: theme.textTheme.titleLarge,
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Text(
                  'Stages (${_stages.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Stage'),
                  onPressed: _addStage,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_stages.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Add stages to define your workflow',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stages.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final adjustedIdx =
                        newIndex > oldIndex ? newIndex - 1 : newIndex;
                    final stage = _stages.removeAt(oldIndex);
                    _stages.insert(adjustedIdx, stage);
                  });
                },
                itemBuilder: (context, index) {
                  final stage = _stages[index];
                  final color = _parseHex(stage.hex);

                  return Card(
                    key: ValueKey('stage_$index'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.drag_handle, size: 20),
                          const SizedBox(width: 8),
                          // Tappable color dot
                          GestureDetector(
                            onTap: () => _showColorPicker(index),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Stage name
                          Expanded(
                            child: TextFormField(
                              initialValue: stage.name,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Stage name',
                              ),
                              onChanged: (v) => stage.name = v,
                            ),
                          ),
                          // Stage type chip
                          PopupMenuButton<String>(
                            tooltip: 'Stage type',
                            initialValue: stage.stageType,
                            onSelected: (v) =>
                                setState(() => stage.stageType = v),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'normal',
                                child: Text('Normal'),
                              ),
                              const PopupMenuItem(
                                value: 'won',
                                child: Text('Won'),
                              ),
                              const PopupMenuItem(
                                value: 'lost',
                                child: Text('Lost'),
                              ),
                            ],
                            child: Chip(
                              label: Text(
                                stage.stageType,
                                style: theme.textTheme.labelSmall,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              backgroundColor: switch (stage.stageType) {
                                'won' => Colors.green.withValues(alpha: 0.1),
                                'lost' => Colors.red.withValues(alpha: 0.1),
                                _ => null,
                              },
                            ),
                          ),
                          // Delete button
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            onPressed: () {
                              setState(() => _stages.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),
            Text(
              'Drag stages to reorder. Tap the color dot to change color. '
              'The first stage is where new records start.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            // Suggestion for won/lost stages
            if (!_stages.any((s) => s.stageType == 'won') ||
                !_stages.any((s) => s.stageType == 'lost')) ...[
              const SizedBox(height: 16),
              Card(
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consider adding "Won" and "Lost" stages to track outcomes.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StageEntry {
  _StageEntry({
    required this.name,
    required this.hex,
    this.stageType = 'normal',
  });

  String name;
  String hex;
  String stageType;
}

class _StageTemplate {
  const _StageTemplate(this.name, this.hex, this.type);

  final String name;
  final String hex;
  final String type;
}
