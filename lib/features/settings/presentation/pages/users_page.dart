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
  String? _roleFilter;
  String? _statusFilter;

  static const _roles = ['admin', 'manager', 'agent', 'viewer'];

  static const _roleDescriptions = {
    'admin': 'Full access — manage users, pipelines, automations, all records',
    'manager': 'Team access — view all records, assign team, run reports',
    'agent': 'Own access — manage assigned records, contacts, tasks',
    'viewer': 'Read-only — view records and reports, no editing',
  };

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

  void _showInviteSheet() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    var role = 'agent';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Invite User',
                    style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 20),
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
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: _roles
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r[0].toUpperCase() + r.substring(1),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => role = v);
                  },
                ),
                if (_roleDescriptions[role] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _roleDescriptions[role]!,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Send Invite'),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    final id = user['id'] as String? ?? '';
    final name = user['display_name'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final role = user['role'] as String? ?? 'agent';
    final status = user['status'] as String? ?? '';
    final isActive = status == 'active';
    final lastLogin = user['last_login_at'] as String?;
    final createdAt = user['created_at'] as String?;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          var currentRole = role;
          var currentActive = isActive;

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollCtrl) {
              final theme = Theme.of(ctx);

              return Scaffold(
                appBar: AppBar(
                  title: Text(name),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  actions: [
                    if (id.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: theme.colorScheme.error),
                        tooltip: 'Delete user',
                        onPressed: () => _deleteUser(ctx, id, name),
                      ),
                  ],
                ),
                body: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(
                                  color:
                                      theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(name,
                                style: theme.textTheme.titleLarge),
                            Text(email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                )),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _RoleBadge(role: currentRole),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: currentActive
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentActive ? 'Active' : 'Inactive',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Details',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600)),
                            const Divider(height: 24),
                            if (lastLogin != null)
                              _infoRow(theme, 'Last Login', lastLogin),
                            if (createdAt != null)
                              _infoRow(theme, 'Joined', createdAt),
                            _infoRow(theme, 'Status', status),
                            _infoRow(theme, 'User ID', id),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Actions',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600)),
                            const Divider(height: 24),
                            // Change role
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                  Icons.admin_panel_settings_outlined),
                              title: const Text('Change Role'),
                              subtitle: Text(
                                  '${currentRole[0].toUpperCase()}'
                                  '${currentRole.substring(1)}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (newRole) async {
                                  try {
                                    await getIt<Dio>().put<void>(
                                      '/api/users/$id',
                                      data: {'role': newRole},
                                    );
                                    setSheetState(
                                        () => currentRole = newRole);
                                    await _loadUsers();
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Failed: $e')),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (_) => _roles
                                    .map((r) => PopupMenuItem(
                                          value: r,
                                          child: Text(
                                            '${r[0].toUpperCase()}'
                                            '${r.substring(1)}',
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            // Toggle active
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              secondary: const Icon(Icons.power_settings_new),
                              title: Text(currentActive
                                  ? 'Deactivate'
                                  : 'Reactivate'),
                              subtitle: Text(currentActive
                                  ? 'Disable this account'
                                  : 'Re-enable this account'),
                              value: currentActive,
                              onChanged: (v) async {
                                try {
                                  await getIt<Dio>().put<void>(
                                    '/api/users/$id',
                                    data: {
                                      'status':
                                          v ? 'active' : 'inactive',
                                    },
                                  );
                                  setSheetState(
                                      () => currentActive = v);
                                  await _loadUsers();
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Failed: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteUser(
      BuildContext ctx, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Delete "$name"?'),
        content: const Text(
          'This will permanently remove this user. '
          'Records they own will need to be reassigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await getIt<Dio>().delete<void>('/api/users/$id');
      if (ctx.mounted) Navigator.pop(ctx);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: theme.textTheme.bodyMedium),
          ),
        ],
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

    var filtered = _users ?? <Map<String, dynamic>>[];
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((u) {
        final name = (u['display_name'] as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }
    if (_roleFilter != null) {
      filtered = filtered
          .where((u) => (u['role'] as String?) == _roleFilter)
          .toList();
    }
    if (_statusFilter != null) {
      filtered = filtered
          .where((u) => (u['status'] as String?) == _statusFilter)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Users${_users != null ? ' (${_users!.length})' : ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadUsers,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All roles'),
                      selected: _roleFilter == null,
                      onSelected: (_) =>
                          setState(() => _roleFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ..._roles.map((r) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              r[0].toUpperCase() + r.substring(1),
                            ),
                            selected: _roleFilter == r,
                            onSelected: (_) =>
                                setState(() => _roleFilter = r),
                          ),
                        )),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Active'),
                      selected: _statusFilter == 'active',
                      onSelected: (_) => setState(() =>
                          _statusFilter =
                              _statusFilter == 'active' ? null : 'active'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Inactive'),
                      selected: _statusFilter == 'inactive',
                      onSelected: (_) => setState(() =>
                          _statusFilter = _statusFilter == 'inactive'
                              ? null
                              : 'inactive'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'users_fab',
        onPressed: _showInviteSheet,
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
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final name =
                        user['display_name'] as String? ?? 'Unknown';
                    final email = user['email'] as String? ?? '';
                    final status = user['status'] as String? ?? '';
                    final role = user['role'] as String? ?? 'agent';
                    final isActive = status == 'active';

                    return ListTile(
                      onTap: () => _showUserDetail(user),
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
                          _RoleBadge(role: role),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  Color get _color => switch (role) {
        'admin' => Colors.red,
        'manager' => Colors.orange,
        'agent' => Colors.blue,
        'viewer' => Colors.grey,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
