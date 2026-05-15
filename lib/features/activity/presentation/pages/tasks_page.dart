import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:cis_crm/features/activity/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          return switch (state) {
            TasksInitial() =>
              const Center(child: Text('Press load to fetch tasks.')),
            TasksLoading() => const Center(child: CircularProgressIndicator()),
            TasksLoaded(:final tasks) => ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) => TaskTile(task: tasks[index]),
              ),
            TasksError(:final message) =>
              Center(child: Text('Error: $message')),
          };
        },
      ),
    );
  }
}
