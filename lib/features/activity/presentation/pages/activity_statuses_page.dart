import 'package:cis_crm/app/injection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ActivityStatusesPage extends StatefulWidget {
  const ActivityStatusesPage({super.key});

  @override
  State<ActivityStatusesPage> createState() => _ActivityStatusesPageState();
}

class _ActivityStatusesPageState extends State<ActivityStatusesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _types = ['task', 'call', 'meeting'];
  static const _typeLabels = {'task': 'Tasks', 'call': 'Calls', 'meeting': 'Meetings'};

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
        title: const Text('Activity Statuses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _types
              .map((t) => Tab(text: _typeLabels[t] ?? t))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _types
            .map((type) => _StatusListTab(activityType: type))
            .toList(),
      ),
    );
  }
}

class _StatusListTab extends StatefulWidget {
  const _StatusListTab({required this.activityType});

  final String activityType;

  @override
  State<_StatusListTab> createState() => _StatusListTabState();
}

class _StatusListTabState extends State<_StatusListTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _statuses;
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
        '/api/activity-statuses',
        queryParameters: {'activity_type': widget.activityType},
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _statuses = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _statuses = []; _loading = false; });
    }
  }

  Future<void> _create() async {
    final result = await _showStatusEditor(context, widget.activityType);
    if (result == null) return;
    try {
      await getIt<Dio>().post<void>('/api/activity-statuses', data: result);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _edit(Map<String, dynamic> status) async {
    final result = await _showStatusEditor(
      context,
      widget.activityType,
      existing: status,
    );
    if (result == null) return;
    try {
      await getIt<Dio>()
          .put<void>('/api/activity-statuses/${status['id']}', data: result);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${status['name']}"?'),
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
          .delete<void>('/api/activity-statuses/${status['id']}');
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
          child: _statuses == null || _statuses!.isEmpty
              ? Center(
                  child: Text('No statuses',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _statuses!.length,
                  onReorder: (oldIndex, newIndex) {
                    // Reorder locally — persist via PUT sort_order.
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _statuses!.removeAt(oldIndex);
                      _statuses!.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final status = _statuses![index];
                    final name = status['name'] as String? ?? '';
                    final phase = status['phase'] as String? ?? 'open';
                    final isDefault = status['is_default'] as bool? ?? false;
                    final isOpen = phase == 'open';

                    return Card(
                      key: ValueKey(status['id']),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isOpen
                              ? Icons.radio_button_unchecked
                              : Icons.check_circle,
                          color: isOpen ? cs.primary : Colors.green,
                        ),
                        title: Row(
                          children: [
                            Text(name,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: (isOpen ? cs.primary : Colors.green)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                phase,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isOpen ? cs.primary : Colors.green,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 6),
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
                              onPressed: () => _edit(status),
                            ),
                            if (!isDefault)
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 18, color: cs.error),
                                onPressed: () => _delete(status),
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
              label: const Text('Add Status'),
            ),
          ),
        ),
      ],
    );
  }
}

Future<Map<String, dynamic>?> _showStatusEditor(
  BuildContext context,
  String activityType, {
  Map<String, dynamic>? existing,
}) {
  final nameCtrl = TextEditingController(
    text: existing?['name'] as String? ?? '',
  );
  var phase = existing?['phase'] as String? ?? 'open';

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(existing != null ? 'Edit Status' : 'New Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Status name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'open', label: Text('Open')),
                ButtonSegment(value: 'closed', label: Text('Closed')),
              ],
              selected: {phase},
              onSelectionChanged: (v) =>
                  setDialogState(() => phase = v.first),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx, {
                'activity_type': activityType,
                'name': name,
                'phase': phase,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
