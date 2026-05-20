import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({required this.task, super.key});

  final CrmTask task;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late CrmTask _task;
  bool _editing = false;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleCtrl = TextEditingController(text: _task.title);
    _descCtrl = TextEditingController(text: _task.description ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = CrmTask(
      id: _task.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : null,
      status: _task.status,
      priority: _task.priority,
      parentType: _task.parentType,
      parentId: _task.parentId,
      createdBy: _task.createdBy,
      createdAt: _task.createdAt,
      updatedAt: DateTime.now(),
      assigneeId: _task.assigneeId,
      dueDate: _task.dueDate,
      completedAt: _task.completedAt,
    );
    context.read<TasksBloc>().add(TaskUpdateRequested(task: updated));
    setState(() {
      _task = updated;
      _editing = false;
    });
  }

  void _updateStatus(TaskStatus status) {
    final updated = CrmTask(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      status: status,
      priority: _task.priority,
      parentType: _task.parentType,
      parentId: _task.parentId,
      createdBy: _task.createdBy,
      createdAt: _task.createdAt,
      updatedAt: DateTime.now(),
      assigneeId: _task.assigneeId,
      dueDate: _task.dueDate,
      completedAt: status == TaskStatus.done ? DateTime.now() : null,
    );
    context.read<TasksBloc>().add(TaskUpdateRequested(task: updated));
    setState(() => _task = updated);
  }

  void _updatePriority(TaskPriority priority) {
    final updated = CrmTask(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      status: _task.status,
      priority: priority,
      parentType: _task.parentType,
      parentId: _task.parentId,
      createdBy: _task.createdBy,
      createdAt: _task.createdAt,
      updatedAt: DateTime.now(),
      assigneeId: _task.assigneeId,
      dueDate: _task.dueDate,
      completedAt: _task.completedAt,
    );
    context.read<TasksBloc>().add(TaskUpdateRequested(task: updated));
    setState(() => _task = updated);
  }

  void _updateDueDate(DateTime? date) {
    final updated = CrmTask(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      status: _task.status,
      priority: _task.priority,
      parentType: _task.parentType,
      parentId: _task.parentId,
      createdBy: _task.createdBy,
      createdAt: _task.createdAt,
      updatedAt: DateTime.now(),
      assigneeId: _task.assigneeId,
      dueDate: date,
      completedAt: _task.completedAt,
    );
    context.read<TasksBloc>().add(TaskUpdateRequested(task: updated));
    setState(() => _task = updated);
  }

  void _confirmDelete() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<TasksBloc>().add(TaskDeleted(_task.id));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.high => Colors.red,
        TaskPriority.medium => Colors.orange,
        TaskPriority.low => Colors.green,
      };

  (String, Color, IconData) _statusInfo(TaskStatus s) => switch (s) {
        TaskStatus.todo => ('To Do', Colors.grey, Icons.radio_button_unchecked),
        TaskStatus.inProgress => (
            'In Progress',
            Colors.blue,
            Icons.timelapse_outlined,
          ),
        TaskStatus.done => ('Done', Colors.green, Icons.check_circle_outline),
      };

  String _fmtDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  String _fmtDateTime(DateTime dt) {
    return '${_fmtDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          if (_editing) ...[
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
            const SizedBox(width: 8),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => setState(() => _editing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_editing)
                      TextField(
                        controller: _titleCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        style: theme.textTheme.headlineSmall,
                        textCapitalization: TextCapitalization.sentences,
                      )
                    else
                      Text(
                        _task.title,
                        style: theme.textTheme.headlineSmall,
                      ),
                    const SizedBox(height: 16),
                    // Status + priority row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        // Status selector
                        SegmentedButton<TaskStatus>(
                          segments: TaskStatus.values.map((s) {
                            final (label, _, icon) = _statusInfo(s);
                            return ButtonSegment(
                              value: s,
                              label: Text(label),
                              icon: Icon(icon, size: 18),
                            );
                          }).toList(),
                          selected: {_task.status},
                          onSelectionChanged: (set) =>
                              _updateStatus(set.first),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Description ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Divider(height: 24),
                    if (_editing)
                      TextField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Add a description...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        minLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      )
                    else
                      Text(
                        _task.description?.isNotEmpty == true
                            ? _task.description!
                            : 'No description',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _task.description?.isNotEmpty == true
                              ? null
                              : colorScheme.onSurfaceVariant,
                          fontStyle: _task.description?.isNotEmpty == true
                              ? null
                              : FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Details card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // Priority
                    ListTile(
                      leading: Icon(
                        Icons.flag_outlined,
                        color: _priorityColor(_task.priority),
                      ),
                      title: const Text('Priority'),
                      trailing: DropdownButton<TaskPriority>(
                        value: _task.priority,
                        underline: const SizedBox.shrink(),
                        items: TaskPriority.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: _priorityColor(p),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  p.name[0].toUpperCase() +
                                      p.name.substring(1),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (p) {
                          if (p != null) _updatePriority(p);
                        },
                      ),
                    ),
                    // Due date
                    ListTile(
                      leading: Icon(
                        Icons.event_outlined,
                        color: _task.dueDate != null &&
                                _task.dueDate!.isBefore(DateTime.now()) &&
                                _task.status != TaskStatus.done
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Due Date'),
                      subtitle: Text(
                        _task.dueDate != null
                            ? _fmtDate(_task.dueDate!)
                            : 'Not set',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_calendar, size: 20),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _task.dueDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) _updateDueDate(picked);
                            },
                          ),
                          if (_task.dueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              tooltip: 'Clear due date',
                              onPressed: () => _updateDueDate(null),
                            ),
                        ],
                      ),
                    ),
                    // Created
                    ListTile(
                      leading: Icon(
                        Icons.calendar_today_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Created'),
                      subtitle: Text(_fmtDateTime(_task.createdAt)),
                    ),
                    // Completed
                    if (_task.completedAt != null)
                      ListTile(
                        leading: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: const Text('Completed'),
                        subtitle: Text(_fmtDateTime(_task.completedAt!)),
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
}
