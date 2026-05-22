import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_config_service.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/presentation/bloc/call_log_cubit.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
          CallLogLoaded(:final callLogs) =>
            _buildLoaded(context, callLogs),
        };
      },
    );
  }

  Widget _buildLoaded(BuildContext context, List<Activity> logs) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.callLogTitle)),
      body: logs.isEmpty
          ? EmptyState(
              icon: Icons.phone_missed,
              title: AppLocalizations.of(context)!.callLogEmpty,
              message: AppLocalizations.of(context)!.callLogEmptyMessage,
            )
          : ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final call = logs[index];
                final direction =
                    call.data['direction'] as String? ?? 'outbound';
                final isInbound = direction == 'inbound';

                return ListTile(
                  leading: Icon(
                    isInbound ? Icons.call_received : Icons.call_made,
                    color: isInbound ? cs.tertiary : cs.primary,
                  ),
                  title: Text(call.title),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          call.statusName,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.yMd().add_jm().format(call.createdAt),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'call_log_fab',
        tooltip: AppLocalizations.of(context)!.logCall,
        onPressed: () => _showLogCallDialog(context),
        child: const Icon(Icons.add_call),
      ),
    );
  }

  void _showLogCallDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var direction = 'outbound';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.logCall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Call with Jane Doe',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: direction,
                  decoration:
                      InputDecoration(labelText: l10n.callDirection),
                  items: const [
                    DropdownMenuItem(
                      value: 'outbound',
                      child: Text('Outbound'),
                    ),
                    DropdownMenuItem(
                      value: 'inbound',
                      child: Text('Inbound'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => direction = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(labelText: l10n.callNotes),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final defaultStatus = await ActivityConfigService.instance
                    .getDefaultStatus('call');
                final now = DateTime.now();
                final activity = ActivityModel(
                  id: '',
                  activityType: ActivityType.call,
                  title: title,
                  statusId: defaultStatus?.id ?? '',
                  statusName: defaultStatus?.name ?? '',
                  statusPhase: defaultStatus?.phase ?? 'open',
                  createdAt: now,
                  updatedAt: now,
                  description: notesCtrl.text.trim().isNotEmpty
                      ? notesCtrl.text.trim()
                      : null,
                  data: {'direction': direction},
                );
                if (context.mounted) {
                  context.read<CallLogCubit>().logCall(activity);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
