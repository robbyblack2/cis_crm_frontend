import 'package:flutter/material.dart';

class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({required this.recordId, super.key});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Detail')),
      body: Center(
        child: Text('Record: $recordId'),
      ),
    );
  }
}
