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
    _StageEntry(name: 'New', color: Colors.blue),
    _StageEntry(name: 'In Progress', color: Colors.orange),
    _StageEntry(name: 'Done', color: Colors.green),
  ];
  bool _creating = false;

  static const _presetColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
  ];

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
      // 1. Create pipeline
      final pipeline = await getIt<PipelineRemoteDataSource>().createPipeline(
        name: name,
        pipelineType: PipelineType.sales,
      );

      // 2. Create stages
      for (var i = 0; i < _stages.length; i++) {
        final stage = _stages[i];
        await getIt<PipelineRemoteDataSource>().createStage(
          pipelineId: pipeline.id,
          name: stage.name,
          position: i,
          color: '#${stage.color.value.toRadixString(16).substring(2)}',
        );
      }

      if (!mounted) return;

      // 3. Reload pipelines and navigate to Kanban
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
      _stages.add(
        _StageEntry(
          name: 'Stage ${_stages.length + 1}',
          color: _presetColors[_stages.length % _presetColors.length],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Pipeline'),
        actions: [
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
            // Pipeline name
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

            // Stages section
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
                    if (newIndex > oldIndex) newIndex--;
                    final stage = _stages.removeAt(oldIndex);
                    _stages.insert(newIndex, stage);
                  });
                },
                itemBuilder: (context, index) {
                  final stage = _stages[index];
                  return Card(
                    key: ValueKey(index),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.drag_handle, size: 20),
                          const SizedBox(width: 8),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: stage.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      title: TextFormField(
                        initialValue: stage.name,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (v) => stage.name = v,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        onPressed: () {
                          setState(() => _stages.removeAt(index));
                        },
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),
            Text(
              'Drag stages to reorder. The first stage is where new records start.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageEntry {
  _StageEntry({required this.name, required this.color});

  String name;
  Color color;
}
