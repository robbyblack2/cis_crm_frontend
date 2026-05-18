import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/reporting/domain/entities/pipeline_summary.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_cubit.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_state.dart';
import 'package:cis_crm/features/reporting/presentation/pages/report_detail_page.dart';
import 'package:cis_crm/features/reporting/presentation/widgets/report_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReportsCubit>()..loadReports(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.reportsTitle)),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return switch (state) {
            ReportsInitial() ||
            ReportsLoading() =>
              PageLoading(label: AppLocalizations.of(context)!.reportsLoading),
            ReportsError(:final message) => PageError(
                title: AppLocalizations.of(context)!.failedToLoadReports,
                message: message,
                onRetry: () => context.read<ReportsCubit>().loadReports(),
              ),
            ReportsLoaded(:final reports) => reports.isEmpty
                ? EmptyState(
                    icon: Icons.bar_chart,
                    title: AppLocalizations.of(context)!.reportsEmptyTitle,
                    message: AppLocalizations.of(context)!.reportsEmptyMessage,
                  )
                : ListView.separated(
                    itemCount: reports.length + 1,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _PipelineSummaryCard();
                      }
                      final report = reports[index - 1];
                      return ReportTile(
                        report: report,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReportDetailPage(report: report),
                          ),
                        ),
                      );
                    },
                  ),
            PipelineSummaryLoading() =>
              const PageLoading(label: 'Loading pipeline summary\u2026'),
            PipelineSummaryLoaded(:final summary) =>
              _PipelineSummaryView(summary: summary),
            // When navigated back from detail, cubit may be in result
            // state; reload the list.
            ReportRunning() ||
            ReportLoaded() =>
              const PageLoading(label: 'Loading reports\u2026'),
          };
        },
      ),
    );
  }
}

class _PipelineSummaryCard extends StatelessWidget {
  const _PipelineSummaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            _showPipelineIdDialog(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 40,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pipeline Summary',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View total records, value, and stage breakdown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPipelineIdDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Pipeline ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Pipeline ID',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final id = controller.text.trim();
              if (id.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                context.read<ReportsCubit>().loadPipelineSummary(id);
              }
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }
}

class _PipelineSummaryView extends StatelessWidget {
  const _PipelineSummaryView({required this.summary});

  final PipelineSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.read<ReportsCubit>().loadReports(),
              ),
              Text(
                'Pipeline Summary',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.people_outlined, color: colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          '${summary.totalRecords}',
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(
                          'Total Records',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(summary.totalValue),
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(
                          'Total Value',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Breakdown by Stage', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final stage in summary.byStage)
                  ListTile(
                    title: Text(stage.stageName),
                    subtitle: Text(
                      '${stage.count} records',
                    ),
                    trailing: Text(
                      currencyFormat.format(stage.value),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (summary.byStage.isEmpty)
                  const ListTile(
                    title: Text('No stages found'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
