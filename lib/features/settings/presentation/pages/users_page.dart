import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>>? _users;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response =
          await getIt<Dio>().get<Map<String, dynamic>>('/api/users');
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _users = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _users = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users == null || _users!.isEmpty
              ? const Center(child: Text('No users'))
              : ListView.separated(
                  itemCount: _users!.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _users![index];
                    final name =
                        user['display_name'] as String? ?? 'Unknown';
                    final email = user['email'] as String? ?? '';
                    final status = user['status'] as String? ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(email),
                      trailing: Chip(
                        label: Text(status),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: status == 'active'
                            ? theme.colorScheme.primaryContainer
                            : theme
                                .colorScheme.surfaceContainerHighest,
                      ),
                    );
                  },
                ),
    );
  }
}
