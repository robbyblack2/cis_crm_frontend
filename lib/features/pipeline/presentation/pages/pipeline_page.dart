import 'dart:async';

import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/network/web_socket_cubit.dart';
import 'package:cis_crm/core/network/web_socket_event.dart';
import 'package:cis_crm/core/responsive/breakpoints.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/pages/record_detail_page.dart';
import 'package:cis_crm/features/pipeline/presentation/widgets/stage_column.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PipelinePage extends StatelessWidget {
  const PipelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PipelineBloc>(
          create: (_) =>
              getIt<PipelineBloc>()..add(const PipelineLoadRequested()),
        ),
        BlocProvider<RecordBloc>(
          create: (_) => getIt<RecordBloc>()..add(const RecordLoadRequested()),
        ),
      ],
      child: const _PipelineView(),
    );
  }
}

class _PipelineView extends StatefulWidget {
  const _PipelineView();

  @override
  State<_PipelineView> createState() => _PipelineViewState();
}

/// Event types that should trigger a record reload.
const _recordEventTypes = {
  'record.created',
  'record.updated',
  'record.moved',
};

class _PipelineViewState extends State<_PipelineView> {
  StreamSubscription<WebSocketEvent>? _wsSub;
  String? _subscribedChannel;

  @override
  void dispose() {
    _unsubscribeChannel();
    _wsSub?.cancel();
    super.dispose();
  }

  void _subscribeToChannel(String pipelineId) {
    final channel = 'pipeline:$pipelineId';
    if (_subscribedChannel == channel) return;

    _unsubscribeChannel();
    _subscribedChannel = channel;

    final wsCubit = context.read<WebSocketCubit>()
      ..subscribe(channel);

    _wsSub?.cancel();
    _wsSub = wsCubit.events.listen((event) {
      if (_recordEventTypes.contains(event.type) && mounted) {
        context.read<RecordBloc>().add(const RecordLoadRequested());
      }
    });
  }

  void _unsubscribeChannel() {
    if (_subscribedChannel != null) {
      try {
        context.read<WebSocketCubit>().unsubscribe(_subscribedChannel!);
      } catch (_) {
        // Context may not be valid during dispose.
      }
      _subscribedChannel = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PipelineBloc, PipelineState>(
      listener: (context, state) {
        if (state is PipelineLoaded && state.pipelines.isNotEmpty) {
          final firstPipeline = state.pipelines.first;
          if (state.kanbanPipeline == null) {
            context.read<PipelineBloc>().add(
                  PipelineKanbanRequested(pipelineId: firstPipeline.id),
                );
          }
          // Subscribe to the active pipeline's WebSocket channel.
          final activePipelineId =
              state.kanbanPipeline?.id ?? firstPipeline.id;
          _subscribeToChannel(activePipelineId);
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        return switch (state) {
          PipelineInitial() =>
            PageLoading(label: l10n.pipelineInitializing),
          PipelineLoading() => PageLoading(label: l10n.pipelineLoading),
          PipelineError(:final message) => PageError(
              title: l10n.failedToLoadPipelines,
              message: message,
              onRetry: () => context
                  .read<PipelineBloc>()
                  .add(const PipelineLoadRequested()),
            ),
          PipelineLoaded() => _LoadedPipelineView(state: state),
        };
      },
    );
  }
}

class _LoadedPipelineView extends StatelessWidget {
  const _LoadedPipelineView({required this.state});

  final PipelineLoaded state;

  @override
  Widget build(BuildContext context) {
    final stages = (state.kanbanStages ?? <Stage>[]).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pipelineTitle),
        actions: [
          if (state.pipelines.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<String>(
                value: state.kanbanPipeline?.id,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                items: state.pipelines
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id != null) {
                    context
                        .read<PipelineBloc>()
                        .add(PipelineKanbanRequested(pipelineId: id));
                  }
                },
              ),
            ),
        ],
      ),
      body: BlocBuilder<RecordBloc, RecordState>(
        builder: (context, recordState) {
          return switch (recordState) {
            RecordInitial() => const Center(
                child: CircularProgressIndicator(),
              ),
            RecordLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            RecordError(:final message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<RecordBloc>()
                          .add(const RecordLoadRequested()),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
            RecordLoaded(:final records) => _KanbanBoard(
                stages: stages,
                records: records,
                pipelineId: state.kanbanPipeline?.id ?? '',
              ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRecordDialog(context),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.newRecord),
        tooltip: AppLocalizations.of(context)!.addNewRecord,
      ),
    );
  }

  void _showCreateRecordDialog(BuildContext context) {
    final titleController = TextEditingController();
    final recordBloc = context.read<RecordBloc>();

    final stages = (state.kanbanStages ?? <Stage>[]).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    if (stages.isEmpty) return;

    var selectedStageId = stages.first.id;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.newRecord),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.title,
                      hintText: l10n.enterRecordTitle,
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStageId,
                    decoration: InputDecoration(
                      labelText: l10n.stage,
                    ),
                    items: stages
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedStageId = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    recordBloc.add(
                      RecordCreateRequested(
                        pipelineId: state.kanbanPipeline?.id ?? '',
                        stageId: selectedStageId,
                        title: title,
                        source: RecordSource.manual,
                      ),
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(l10n.create),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    required this.stages,
    required this.records,
    required this.pipelineId,
  });

  final List<Stage> stages;
  final List<PipelineRecord> records;
  final String pipelineId;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return EmptyState(
        icon: Icons.view_kanban_outlined,
        title: l10n.noStagesConfigured,
        message: l10n.noStagesConfiguredMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final windowSize = windowSizeFor(constraints.maxWidth);
        final columnWidth = switch (windowSize) {
          WindowSize.compact => 280.0,
          WindowSize.medium => 300.0,
          WindowSize.expanded => 320.0,
        };

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                SizedBox(
                  width: columnWidth,
                  height: constraints.maxHeight - 32,
                  child: StageColumn(
                    stage: stages[i],
                    records: records
                        .where((r) => r.stageId == stages[i].id)
                        .toList(),
                    onRecordTap: (record) => _navigateToDetail(
                      context,
                      record,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, PipelineRecord record) {
    final pipelineBloc = context.read<PipelineBloc>();
    final recordBloc = context.read<RecordBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<PipelineBloc>.value(value: pipelineBloc),
            BlocProvider<RecordBloc>.value(value: recordBloc),
          ],
          child: RecordDetailPage(recordId: record.id),
        ),
      ),
    );
  }
}
