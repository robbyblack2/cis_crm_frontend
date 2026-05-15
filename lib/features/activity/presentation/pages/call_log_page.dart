import 'package:cis_crm/features/activity/presentation/bloc/call_log_cubit.dart';
import 'package:cis_crm/features/activity/presentation/widgets/call_log_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CallLogPage extends StatelessWidget {
  const CallLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Log')),
      body: BlocBuilder<CallLogCubit, CallLogState>(
        builder: (context, state) {
          return switch (state) {
            CallLogInitial() =>
              const Center(child: Text('Press load to fetch call logs.')),
            CallLogLoading() =>
              const Center(child: CircularProgressIndicator()),
            CallLogLoaded(:final callLogs) => ListView.builder(
                itemCount: callLogs.length,
                itemBuilder: (context, index) =>
                    CallLogTile(callLog: callLogs[index]),
              ),
            CallLogError(:final message) =>
              Center(child: Text('Error: $message')),
          };
        },
      ),
    );
  }
}
