import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/reporting/domain/entities/report.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_cubit.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_state.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({required this.report, super.key});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReportsCubit>()..runReport(report.id),
      child: _ReportDetailView(report: report),
    );
  }
}

class _ReportDetailView extends StatelessWidget {
  const _ReportDetailView({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.name),
        actions: [
          IconButton(
            onPressed: () async {
              final url = await context
                  .read<ReportsCubit>()
                  .exportReport(report.id);
              if (!context.mounted) return;
              if (url != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export ready: $url')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!
                          .exportNotImplemented,
                    ),
                  ),
                );
              }
            },
            tooltip: AppLocalizations.of(context)!.exportReport,
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return switch (state) {
            ReportsInitial() ||
            ReportsLoading() ||
            ReportRunning() =>
              PageLoading(label: AppLocalizations.of(context)!.runningReport),
            ReportsError(:final message) => PageError(
                title: AppLocalizations.of(context)!.reportFailed,
                message: message,
                onRetry: () =>
                    context.read<ReportsCubit>().runReport(report.id),
              ),
            ReportLoaded(:final result) => result.rows.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.noDataReturned,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        columns: result.columns
                            .map(
                              (String col) => DataColumn(label: Text(col)),
                            )
                            .toList(),
                        rows: result.rows
                            .map(
                              (Map<String, dynamic> row) => DataRow(
                                cells: result.columns
                                    .map(
                                      (String col) => DataCell(
                                        Text(
                                          row[col]?.toString() ?? '',
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
            // List / pipeline-summary states shouldn't appear on this page.
            ReportsLoaded() ||
            PipelineSummaryLoading() ||
            PipelineSummaryLoaded() =>
              PageLoading(label: AppLocalizations.of(context)!.runningReport),
          };
        },
      ),
    );
  }
}
