import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:cis_crm/features/activity/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TasksBloc>()..add(const TasksLoadRequested()),
      child: const _TasksView(),
    );
  }
}

class _TasksView extends StatefulWidget {
  const _TasksView();

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  TaskStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        return switch (state) {
          TasksInitial() ||
          TasksLoading() =>
            const PageLoading(label: 'Loading tasks...'),
          TasksError(:final message) => PageError(
              title: 'Failed to load tasks',
              message: message,
              onRetry: () =>
                  context.read<TasksBloc>().add(const TasksLoadRequested()),
            ),
          TasksLoaded(:final tasks) => _buildLoaded(context, tasks),
        };
      },
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    var selectedPriority = TaskPriority.medium;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Create Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter task title',
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                ),
                items: TaskPriority.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p.name[0].toUpperCase() +
                              p.name.substring(1),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedPriority = value);
                  }
                },
              ),
            ],
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
                final now = DateTime.now();
                final task = CrmTask(
                  id: '',
                  title: title,
                  status: TaskStatus.todo,
                  priority: selectedPriority,
                  parentType: '',
                  parentId: '',
                  createdBy: '',
                  createdAt: now,
                  updatedAt: now,
                );
                context.read<TasksBloc>().add(TaskCreateRequested(task: task));
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<CrmTask> tasks) {
    final filtered = _filter == null
        ? tasks
        : tasks.where((t) => t.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterChips(
            selected: _filter,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const EmptyState(
              icon: Icons.task_alt,
              title: 'No tasks yet',
              message: 'Tap + to create your first task.',
            )
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final task = filtered[index];
                return TaskTile(
                  task: task,
                  onStatusToggled: (updated) =>
                      context.read<TasksBloc>().add(TaskUpdated(updated)),
                  onDeleted: (id) =>
                      context.read<TasksBloc>().add(TaskDeleted(id)),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add task',
        onPressed: () => _showCreateTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
  });

  final TaskStatus? selected;
  final ValueChanged<TaskStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _chip(context, label: 'All', value: null),
          const SizedBox(width: 8),
          _chip(context, label: 'Todo', value: TaskStatus.todo),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'In Progress',
            value: TaskStatus.inProgress,
          ),
          const SizedBox(width: 8),
          _chip(context, label: 'Done', value: TaskStatus.done),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required TaskStatus? value,
  }) {
    final isSelected = selected == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }
}
