import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_cubit.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_state.dart';
import 'package:cis_crm/features/reporting/presentation/pages/report_detail_page.dart';
import 'package:cis_crm/features/reporting/presentation/widgets/report_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      appBar: AppBar(title: const Text('Reports')),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return switch (state) {
            ReportsInitial() ||
            ReportsLoading() =>
              const PageLoading(label: 'Loading reports\u2026'),
            ReportsError(:final message) => PageError(
                title: 'Failed to load reports',
                message: message,
                onRetry: () => context.read<ReportsCubit>().loadReports(),
              ),
            ReportsLoaded(:final reports) => reports.isEmpty
                ? const EmptyState(
                    icon: Icons.bar_chart,
                    title: 'No reports',
                    message: 'Reports will appear here once created.',
                  )
                : ListView.separated(
                    itemCount: reports.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final report = reports[index];
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
