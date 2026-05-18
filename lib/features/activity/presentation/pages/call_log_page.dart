import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/activity/domain/entities/call_log.dart';
import 'package:cis_crm/features/activity/presentation/bloc/call_log_cubit.dart';
import 'package:cis_crm/features/activity/presentation/widgets/call_log_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
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
            PageLoading(label: AppLocalizations.of(context)!.callLogLoading),
          CallLogError(:final message) => PageError(
              title: AppLocalizations.of(context)!.failedToLoadCallLogs,
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.callLogTitle)),
      body: logs.isEmpty
          ? EmptyState(
              icon: Icons.phone_missed,
              title: AppLocalizations.of(context)!.callLogEmpty,
              message: AppLocalizations.of(context)!.callLogEmptyMessage,
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) => CallLogTile(log: logs[index]),
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: AppLocalizations.of(context)!.logCall,
        onPressed: () {
          // TODO(nav): Navigate to call logging form.
        },
        child: const Icon(Icons.add_call),
      ),
    );
  }
}
