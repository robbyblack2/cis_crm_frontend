import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SavedViewsPage extends StatefulWidget {
  const SavedViewsPage({super.key});

  @override
  State<SavedViewsPage> createState() => _SavedViewsPageState();
}

class _SavedViewsPageState extends State<SavedViewsPage> {
  var _entityType = 'record';
  List<Map<String, dynamic>>? _views;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/saved-views',
        queryParameters: {'entity_type': _entityType},
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _views = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _views = []; _loading = false; });
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final filterCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Saved View'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'View name'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: filterCtrl,
              decoration: const InputDecoration(
                labelText: 'Filter (JSON)',
                hintText: '{"status": "active"}',
              ),
              maxLines: 3,
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
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await getIt<Dio>().post<void>(
                  '/api/saved-views',
                  data: {
                    'name': name,
                    'entity_type': _entityType,
                    'filters': filterCtrl.text.trim().isNotEmpty
                        ? filterCtrl.text.trim()
                        : '{}',
                  },
                );
                await _load();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteView(String id) async {
    try {
      await getIt<Dio>().delete<void>('/api/saved-views/$id');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entities = ['record', 'contact', 'company', 'product'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Views'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: entities
                  .map(
                    (t) => ButtonSegment(
                      value: t,
                      label: Text(
                        '${t[0].toUpperCase()}${t.substring(1)}s',
                      ),
                    ),
                  )
                  .toList(),
              selected: {_entityType},
              onSelectionChanged: (s) {
                setState(() => _entityType = s.first);
                _load();
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'saved_views_fab',
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _views == null || _views!.isEmpty
              ? const EmptyState(
                  icon: Icons.view_list_outlined,
                  title: 'No saved views',
                  message: 'Tap + to save a custom view.',
                )
              : ListView.separated(
                  itemCount: _views!.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final view = _views![index];
                    return ListTile(
                      leading: Icon(
                        Icons.view_list,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        view['name'] as String? ?? 'View',
                      ),
                      subtitle: Text(
                        view['entity_type'] as String? ?? '',
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _deleteView(
                          view['id'] as String? ?? '',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
