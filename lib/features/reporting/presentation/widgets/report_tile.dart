import 'package:cis_crm/features/reporting/domain/entities/report.dart';
import 'package:flutter/material.dart';

class ReportTile extends StatelessWidget {
  const ReportTile({
    required this.report,
    this.onTap,
    super.key,
  });

  final Report report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bar_chart),
      title: Text(report.name),
      subtitle: report.description != null
          ? Text(
              report.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
