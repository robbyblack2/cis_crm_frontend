import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/activity/domain/entities/call_direction.dart';
import 'package:cis_crm/features/activity/domain/entities/call_log.dart';
import 'package:cis_crm/features/activity/domain/entities/call_outcome.dart';
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
        onPressed: () => _showLogCallDialog(context),
        child: const Icon(Icons.add_call),
      ),
    );
  }

  void _showLogCallDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contactIdController = TextEditingController();
    final durationController = TextEditingController();
    final notesController = TextEditingController();
    var direction = CallDirection.outbound;
    var outcome = CallOutcome.connected;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.logCall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: contactIdController,
                  decoration: InputDecoration(labelText: l10n.callContactId),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CallDirection>(
                  value: direction,
                  decoration: InputDecoration(labelText: l10n.callDirection),
                  items: CallDirection.values
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => direction = v);
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CallOutcome>(
                  value: outcome,
                  decoration: InputDecoration(labelText: l10n.callOutcome),
                  items: CallOutcome.values
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Text(o.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => outcome = v);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(labelText: l10n.callDuration),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: l10n.callNotes),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final contactId = contactIdController.text.trim();
                if (contactId.isEmpty) return;
                final callLog = CallLog(
                  id: '',
                  contactId: contactId,
                  direction: direction,
                  outcome: outcome,
                  durationSeconds:
                      int.tryParse(durationController.text.trim()),
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                  loggedBy: '',
                  createdAt: DateTime.now(),
                );
                context.read<CallLogCubit>().logCall(callLog);
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
