import 'package:cis_crm/features/reporting/domain/entities/report.dart';
import 'package:flutter/material.dart';

class ReportTile extends StatelessWidget {
  const ReportTile({required this.report, super.key});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(report.name),
      subtitle: report.description != null ? Text(report.description!) : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
