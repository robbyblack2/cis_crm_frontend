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

  (String label, Color color, IconData icon) _statusInfo(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => ('To Do', Colors.grey, Icons.radio_button_unchecked),
      TaskStatus.inProgress => (
          'In Progress',
          Colors.blue,
          Icons.timelapse_outlined,
        ),
      TaskStatus.done => ('Done', Colors.green, Icons.check_circle_outline),
    };
  }

  TaskStatus _nextStatus(TaskStatus current) {
    return switch (current) {
      TaskStatus.todo => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.done,
      TaskStatus.done => TaskStatus.todo,
    };
  }

  bool _isOverdue(CrmTask task) {
    if (task.dueDate == null || task.status == TaskStatus.done) return false;
    return task.dueDate!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = task.status == TaskStatus.done;
    final overdue = _isOverdue(task);
    final (statusLabel, statusColor, statusIcon) = _statusInfo(task.status);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colorScheme.error,
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      onDismissed: (_) => onDeleted(task.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: overdue
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status button (cycles through states on tap)
                InkWell(
                  onTap: () {
                    final next = _nextStatus(task.status);
                    final toggled = CrmTask(
                      id: task.id,
                      title: task.title,
                      status: next,
                      priority: task.priority,
                      parentType: task.parentType,
                      parentId: task.parentId,
                      createdBy: task.createdBy,
                      createdAt: task.createdAt,
                      updatedAt: task.updatedAt,
                      description: task.description,
                      assigneeId: task.assigneeId,
                      dueDate: task.dueDate,
                      completedAt:
                          next == TaskStatus.done ? DateTime.now() : null,
                    );
                    onStatusToggled(toggled);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: isDone
                            ? theme.textTheme.titleSmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Description preview
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Meta row: status chip + due date + priority
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _priorityColor(task.priority)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 12,
                                  color: _priorityColor(task.priority),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.priority.name[0].toUpperCase() +
                                      task.priority.name.substring(1),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _priorityColor(task.priority),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Due date
                          if (task.dueDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_outlined,
                                  size: 14,
                                  color: overdue
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(task.dueDate!),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: overdue
                                        ? colorScheme.error
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight:
                                        overdue ? FontWeight.w600 : null,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
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
