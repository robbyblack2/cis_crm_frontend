import 'package:cis_crm/features/activity/domain/entities/call_log.dart';
import 'package:flutter/material.dart';

class CallLogTile extends StatelessWidget {
  const CallLogTile({required this.callLog, super.key});

  final CallLog callLog;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(callLog.contactId),
      subtitle: Text(callLog.outcome.name),
      trailing: Text(callLog.direction.name),
    );
  }
}
