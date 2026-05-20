import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// Preset colors for tags
const _tagColors = [
  Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
  Color(0xFF22C55E), Color(0xFF14B8A6), Color(0xFF3B82F6),
  Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
  Color(0xFF64748B), Color(0xFF78716C), Color(0xFF0EA5E9),
];

Color _colorForTag(String name) {
  var hash = 0;
  for (var i = 0; i < name.length; i++) {
    hash = name.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return _tagColors[hash.abs() % _tagColors.length];
}

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  List<Map<String, dynamic>>? _tags;
  bool _loading = true;
  String _search = '';

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

  bool _isDuplicate(String name) {
    if (_tags == null) return false;
    final lower = name.toLowerCase();
    return _tags!.any(
      (t) => (t['name'] as String? ?? '').toLowerCase() == lower,
    );
  }

  void _showCreateDialog() {
    final ctrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final name = ctrl.text.trim();
          final isDup = name.isNotEmpty && _isDuplicate(name);
          final color = name.isNotEmpty ? _colorForTag(name) : Colors.grey;

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create Tag', style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Tag name',
                    border: const OutlineInputBorder(),
                    errorText: isDup ? 'Tag "$name" already exists' : null,
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                if (name.isNotEmpty && !isDup) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Preview: ', style: Theme.of(ctx).textTheme.labelMedium),
                      Chip(
                        avatar: CircleAvatar(radius: 6, backgroundColor: color),
                        label: Text(name),
                        backgroundColor: color.withValues(alpha: 0.1),
                        side: BorderSide(color: color.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isDup || name.isEmpty
                      ? null
                      : () async {
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
        },
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
    final colorScheme = theme.colorScheme;

    final filtered = _search.isEmpty
        ? _tags
        : _tags?.where((t) =>
            (t['name'] as String? ?? '')
                .toLowerCase()
                .contains(_search.toLowerCase()),
          ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tags${_tags != null ? ' (${_tags!.length})' : ''}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tags_fab',
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Tag'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tags == null || _tags!.isEmpty
              ? const EmptyState(
                  icon: Icons.label_outline,
                  title: 'No tags',
                  message: 'Tap + to create a tag.',
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search tags...',
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
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tag = filtered![index];
                          final name = tag['name'] as String? ?? '';
                          final id = tag['id'] as String? ?? '';
                          final color = _colorForTag(name);

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(Icons.label, size: 16, color: color),
                            ),
                            title: Text(name),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: colorScheme.error,
                              ),
                              onPressed: () => _deleteTag(id),
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
