import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/activity/domain/entities/call_log.dart';
import 'package:cis_crm/features/activity/presentation/bloc/call_log_cubit.dart';
import 'package:cis_crm/features/activity/presentation/widgets/call_log_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CallLogPage extends StatelessWidget {
  const CallLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CallLogCubit>()..loadCallLogs(),
      child: const _CallLogView(),
    );
  }
}

class _CallLogView extends StatelessWidget {
  const _CallLogView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallLogCubit, CallLogState>(
      builder: (context, state) {
        return switch (state) {
          CallLogInitial() ||
          CallLogLoading() =>
            const PageLoading(label: 'Loading call logs...'),
          CallLogError(:final message) => PageError(
              title: 'Failed to load call logs',
              message: message,
              onRetry: () => context.read<CallLogCubit>().loadCallLogs(),
            ),
          CallLogLoaded(:final callLogs) => _buildLoaded(context, callLogs),
        };
      },
    );
  }

  Widget _buildLoaded(BuildContext context, List<CallLog> logs) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Log')),
      body: logs.isEmpty
          ? const EmptyState(
              icon: Icons.phone_missed,
              title: 'No call logs',
              message: 'Tap + to log your first call.',
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) => CallLogTile(log: logs[index]),
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Log a call',
        onPressed: () {
          // TODO(nav): Navigate to call logging form.
        },
        child: const Icon(Icons.add_call),
      ),
    );
  }
}
