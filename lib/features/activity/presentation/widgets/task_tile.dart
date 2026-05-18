import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:flutter/material.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    required this.onStatusToggled,
    required this.onDeleted,
    this.onTap,
    super.key,
  });

  final CrmTask task;
  final ValueChanged<CrmTask> onStatusToggled;
  final ValueChanged<String> onDeleted;
  final VoidCallback? onTap;

  Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => Colors.red,
      TaskPriority.medium => Colors.orange,
      TaskPriority.low => Colors.green,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.status == TaskStatus.done;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) => onDeleted(task.id),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: isDone,
          onChanged: (_) {
            final newStatus = isDone ? TaskStatus.todo : TaskStatus.done;
            final toggled = CrmTask(
              id: task.id,
              title: task.title,
              status: newStatus,
              priority: task.priority,
              parentType: task.parentType,
              parentId: task.parentId,
              createdBy: task.createdBy,
              createdAt: task.createdAt,
              updatedAt: task.updatedAt,
              description: task.description,
              assigneeId: task.assigneeId,
              dueDate: task.dueDate,
              completedAt: task.completedAt,
            );
            onStatusToggled(toggled);
          },
        ),
        title: Text(
          task.title,
          style: isDone
              ? theme.textTheme.bodyLarge?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : theme.textTheme.bodyLarge,
        ),
        subtitle: task.dueDate != null
            ? Text(
                'Due ${_formatDate(task.dueDate!)}',
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: Tooltip(
          message: '${task.priority.name} priority',
          child: Icon(
            Icons.circle,
            size: 12,
            color: _priorityColor(task.priority),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
