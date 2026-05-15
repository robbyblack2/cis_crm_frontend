import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:flutter/material.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({required this.task, super.key});

  final CrmTask task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      subtitle: Text(task.status.name),
      trailing: Text(task.priority.name),
    );
  }
}
