import 'package:cis_crm/features/reporting/presentation/bloc/reports_cubit.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_state.dart';
import 'package:cis_crm/features/reporting/presentation/widgets/report_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return switch (state) {
            ReportsInitial() => const Center(
                child: Text('No reports loaded.'),
              ),
            ReportsLoading() || ReportRunning() => const Center(
                child: CircularProgressIndicator(),
              ),
            ReportsLoaded(:final reports) => ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) =>
                    ReportTile(report: reports[index]),
              ),
            ReportLoaded() => const Center(
                child: Text('Report result loaded.'),
              ),
            ReportsError(:final message) => Center(
                child: Text(message),
              ),
          };
        },
      ),
    );
  }
}
