import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  List<Map<String, dynamic>>? _tags;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response =
          await getIt<Dio>().get<Map<String, dynamic>>('/api/tags');
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _tags = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _tags = []; _loading = false; });
    }
  }

  void _showCreateDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Tag'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Tag name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await getIt<Dio>().post<void>(
                  '/api/tags',
                  data: {'name': name},
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

  Future<void> _deleteTag(String id) async {
    try {
      await getIt<Dio>().delete<void>('/api/tags/$id');
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

    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tags_fab',
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tags == null || _tags!.isEmpty
              ? const EmptyState(
                  icon: Icons.label_outline,
                  title: 'No tags',
                  message: 'Tap + to create a tag.',
                )
              : ListView.separated(
                  itemCount: _tags!.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tag = _tags![index];
                    final name = tag['name'] as String? ?? '';
                    final id = tag['id'] as String? ?? '';
                    return ListTile(
                      leading: Icon(
                        Icons.label_outline,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(name),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _deleteTag(id),
                      ),
                    );
                  },
                ),
    );
  }
}
