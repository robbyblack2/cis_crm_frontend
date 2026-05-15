import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/reporting/domain/entities/report.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_cubit.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_state.dart';
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
            onPressed: () {
              // TODO(export): Implement report export.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export not yet implemented')),
              );
            },
            tooltip: 'Export report',
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
              const PageLoading(label: 'Running report\u2026'),
            ReportsError(:final message) => PageError(
                title: 'Report failed',
                message: message,
                onRetry: () =>
                    context.read<ReportsCubit>().runReport(report.id),
              ),
            ReportLoaded(:final result) => result.rows.isEmpty
                ? Center(
                    child: Text(
                      'No data returned',
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
            // List states shouldn't appear on this page.
            ReportsLoaded() => const PageLoading(label: 'Running report\u2026'),
          };
        },
      ),
    );
  }
}
