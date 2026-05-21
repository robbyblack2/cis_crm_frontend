import 'package:cis_crm/app/injection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ActivitySubtypesPage extends StatefulWidget {
  const ActivitySubtypesPage({super.key});

  @override
  State<ActivitySubtypesPage> createState() => _ActivitySubtypesPageState();
}

class _ActivitySubtypesPageState extends State<ActivitySubtypesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _types = ['task', 'call', 'meeting'];
  static const _typeLabels = {
    'task': 'Tasks',
    'call': 'Calls',
    'meeting': 'Meetings',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Subtypes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _types.map((t) => Tab(text: _typeLabels[t] ?? t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            _types.map((type) => _SubtypeListTab(activityType: type)).toList(),
      ),
    );
  }
}

class _SubtypeListTab extends StatefulWidget {
  const _SubtypeListTab({required this.activityType});

  final String activityType;

  @override
  State<_SubtypeListTab> createState() => _SubtypeListTabState();
}

class _SubtypeListTabState extends State<_SubtypeListTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _subtypes;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/activity-subtypes',
        queryParameters: {'activity_type': widget.activityType},
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _subtypes = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _subtypes = []; _loading = false; });
    }
  }

  Future<void> _create() async {
    final name = await _showNameEditor(context);
    if (name == null || name.isEmpty) return;
    try {
      await getIt<Dio>().post<void>('/api/activity-subtypes', data: {
        'activity_type': widget.activityType,
        'name': name,
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _edit(Map<String, dynamic> subtype) async {
    final name = await _showNameEditor(
      context,
      existing: subtype['name'] as String?,
    );
    if (name == null || name.isEmpty) return;
    try {
      await getIt<Dio>().put<void>(
        '/api/activity-subtypes/${subtype['id']}',
        data: {'name': name},
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> subtype) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${subtype['name']}"?'),
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
      await getIt<Dio>()
          .delete<void>('/api/activity-subtypes/${subtype['id']}');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: _subtypes == null || _subtypes!.isEmpty
              ? Center(
                  child: Text('No subtypes',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subtypes!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final subtype = _subtypes![index];
                    final name = subtype['name'] as String? ?? '';
                    final isDefault = subtype['is_default'] as bool? ?? false;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.category_outlined,
                            color: cs.onSurfaceVariant),
                        title: Row(
                          children: [
                            Text(name,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Default',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontSize: 10,
                                    )),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _edit(subtype),
                            ),
                            if (!isDefault)
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 18, color: cs.error),
                                onPressed: () => _delete(subtype),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Add Subtype'),
            ),
          ),
        ),
      ],
    );
  }
}

Future<String?> _showNameEditor(
  BuildContext context, {
  String? existing,
}) {
  final ctrl = TextEditingController(text: existing ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(existing != null ? 'Edit Subtype' : 'New Subtype'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Name',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
