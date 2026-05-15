import 'package:cis_crm/features/reporting/presentation/bloc/reports_cubit.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Results')),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return switch (state) {
            ReportRunning() => const Center(
                child: CircularProgressIndicator(),
              ),
            ReportLoaded(:final result) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: result.columns
                      .map((c) => DataColumn(label: Text(c)))
                      .toList(),
                  rows: result.rows
                      .map(
                        (row) => DataRow(
                          cells: result.columns
                              .map(
                                (c) => DataCell(Text('${row[c]}')),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ReportsError(:final message) => Center(
                child: Text(message),
              ),
            _ => const Center(child: Text('Run a report to see results.')),
          };
        },
      ),
    );
  }
}
