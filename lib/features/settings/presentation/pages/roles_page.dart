import 'package:cis_crm/app/injection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Permission categories and their individual permissions.
const _permissionCategories = <String, List<String>>{
  'Contacts': [
    'contacts.view',
    'contacts.create',
    'contacts.edit',
    'contacts.delete',
  ],
  'Pipeline': [
    'pipeline.view',
    'pipeline.create',
    'pipeline.edit',
    'pipeline.delete',
    'pipeline.manage',
  ],
  'Calendar': ['calendar.view', 'calendar.edit'],
  'Activities': [
    'activities.view',
    'activities.create',
    'activities.edit',
    'activities.delete',
  ],
  'Automation': ['automation.view', 'automation.manage'],
  'Settings': ['settings.view', 'settings.manage'],
  'Users': ['users.view', 'users.manage'],
};

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  List<Map<String, dynamic>>? _roles;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response =
          await getIt<Dio>().get<Map<String, dynamic>>('/api/roles');
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _roles = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _roles = []; _loading = false; });
    }
  }

  Future<void> _createRole() async {
    final result = await _showRoleEditor(context);
    if (result != null) {
      try {
        await getIt<Dio>().post<void>('/api/roles', data: result);
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create role: $e')),
          );
        }
      }
    }
  }

  Future<void> _editRole(Map<String, dynamic> role) async {
    final result = await _showRoleEditor(context, existing: role);
    if (result != null) {
      try {
        await getIt<Dio>().put<void>(
          '/api/roles/${role['id']}',
          data: result,
        );
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update role: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteRole(Map<String, dynamic> role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${role['name']}"?'),
        content: const Text(
          'Users assigned to this role will lose these permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
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
      await getIt<Dio>().delete<void>('/api/roles/${role['id']}');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Roles & Permissions')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'roles_fab',
        onPressed: _createRole,
        icon: const Icon(Icons.add),
        label: const Text('New Role'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _roles == null || _roles!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined,
                          size: 48, color: cs.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text('No roles defined',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _roles!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final role = _roles![index];
                    final name = role['name'] as String? ?? '';
                    final permissions =
                        (role['permissions'] as List<dynamic>?) ?? [];
                    final isSystem = role['is_system'] as bool? ?? false;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isSystem
                              ? Icons.shield_outlined
                              : Icons.admin_panel_settings_outlined,
                          color: isSystem ? cs.primary : cs.onSurfaceVariant,
                        ),
                        title: Row(
                          children: [
                            Text(name,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            if (isSystem) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('System',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontSize: 10,
                                    )),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${permissions.length} permission${permissions.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit',
                              onPressed: () => _editRole(role),
                            ),
                            if (!isSystem)
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 18, color: cs.error),
                                tooltip: 'Delete',
                                onPressed: () => _deleteRole(role),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Shows a side-panel-style editor for creating or editing a role.
Future<Map<String, dynamic>?> _showRoleEditor(
  BuildContext context, {
  Map<String, dynamic>? existing,
}) async {
  final nameCtrl = TextEditingController(
    text: existing?['name'] as String? ?? '',
  );
  final existingPerms =
      (existing?['permissions'] as List<dynamic>?)?.cast<String>().toSet() ??
          <String>{};
  final selected = Set<String>.from(existingPerms);

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;

          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
              child: Scaffold(
                appBar: AppBar(
                  title: Text(existing != null ? 'Edit Role' : 'New Role'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx, {
                          'name': name,
                          'permissions': selected.toList(),
                        });
                      },
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: existing == null,
                      decoration: const InputDecoration(
                        labelText: 'Role name',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Manager',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 24),
                    Text('Permissions',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ..._permissionCategories.entries.map((category) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category.key,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 0,
                            children:
                                category.value.map((perm) {
                              final label = perm.split('.').last;
                              return SizedBox(
                                width: 200,
                                child: CheckboxListTile(
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(label,
                                      style: theme.textTheme.bodySmall),
                                  value: selected.contains(perm),
                                  onChanged: (v) {
                                    setDialogState(() {
                                      if (v == true) {
                                        selected.add(perm);
                                      } else {
                                        selected.remove(perm);
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
