import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
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
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
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

  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    var role = 'agent';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin'),
                  ),
                  DropdownMenuItem(
                    value: 'manager',
                    child: Text('Manager'),
                  ),
                  DropdownMenuItem(
                    value: 'agent',
                    child: Text('Agent'),
                  ),
                  DropdownMenuItem(
                    value: 'viewer',
                    child: Text('Viewer'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => role = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await getIt<Dio>().post<void>(
                    '/api/users',
                    data: {
                      'email': email,
                      'display_name': nameCtrl.text.trim().isNotEmpty
                          ? nameCtrl.text.trim()
                          : email.split('@').first,
                      'role': role,
                    },
                  );
                  await _loadUsers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invited $email')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to invite: $e')),
                    );
                  }
                }
              },
              child: const Text('Invite'),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) => switch (role) {
        'admin' => Colors.red,
        'manager' => Colors.orange,
        'agent' => Colors.blue,
        'viewer' => Colors.grey,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = _search.isEmpty
        ? _users
        : _users?.where((u) {
            final name =
                (u['display_name'] as String? ?? '').toLowerCase();
            final email = (u['email'] as String? ?? '').toLowerCase();
            final q = _search.toLowerCase();
            return name.contains(q) || email.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Users${_users != null ? ' (${_users!.length})' : ''}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'users_fab',
        onPressed: _showInviteDialog,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Invite'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users == null || _users!.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No users',
                  message: 'Tap Invite to add a team member.',
                )
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered?.length ?? 0,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = filtered![index];
                          final name =
                              user['display_name'] as String? ?? 'Unknown';
                          final email = user['email'] as String? ?? '';
                          final status = user['status'] as String? ?? '';
                          final role = user['role'] as String? ?? 'agent';
                          final isActive = status == 'active';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: isActive
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text(email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Role badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _roleColor(role)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    role[0].toUpperCase() +
                                        role.substring(1),
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: _roleColor(role),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status dot
                                Tooltip(
                                  message: isActive ? 'Active' : 'Inactive',
                                  child: Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
