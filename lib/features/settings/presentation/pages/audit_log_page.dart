import 'package:cis_crm/app/injection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  List<Map<String, dynamic>>? _entries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response =
          await getIt<Dio>().get<Map<String, dynamic>>('/api/audit-log');
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _entries = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _entries = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries == null || _entries!.isEmpty
              ? Center(
                  child: Text(
                    'No audit log entries',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  itemCount: _entries!.length,
                  itemBuilder: (context, index) {
                    final entry = _entries![index];
                    final action =
                        entry['action'] as String? ?? 'Unknown';
                    final entityType =
                        entry['entity_type'] as String? ?? '';
                    final actor =
                        entry['actor_email'] as String? ??
                            entry['actor_id'] as String? ??
                            '';
                    final ts = entry['created_at'] as String? ?? '';

                    return ListTile(
                      leading: Icon(
                        _actionIcon(action),
                        color: theme.colorScheme.primary,
                      ),
                      title: Text('$action $entityType'),
                      subtitle: Text('$actor\n$ts'),
                      isThreeLine: true,
                    );
                  },
                ),
    );
  }

  IconData _actionIcon(String action) {
    return switch (action.toLowerCase()) {
      'create' || 'created' => Icons.add_circle_outline,
      'update' || 'updated' => Icons.edit_outlined,
      'delete' || 'deleted' => Icons.delete_outline,
      'move' || 'moved' => Icons.swap_horiz,
      'login' => Icons.login,
      'logout' => Icons.logout,
      _ => Icons.history,
    };
  }
}
