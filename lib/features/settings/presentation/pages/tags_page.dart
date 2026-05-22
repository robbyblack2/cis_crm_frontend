import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/utils/tag_color_cache.dart';
import 'package:cis_crm/core/widgets/crm_tag_chip.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

Color _parseHex(String hex) {
  if (hex.startsWith('#') && hex.length == 7) {
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }
  return Colors.grey;
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
        final tags = list?.cast<Map<String, dynamic>>() ?? [];
        // Populate tag color cache so CrmTagChip renders correct colors.
        for (final tag in tags) {
          final name = tag['name'] as String?;
          final color = tag['color'] as String?;
          if (name != null && color != null && color.isNotEmpty) {
            TagColorCache.instance.put(name, color);
          }
        }
        setState(() {
          _tags = tags;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _tags = []; _loading = false; });
    }
  }

  bool _isDuplicate(String name, {String? excludeId}) {
    if (_tags == null) return false;
    final lower = name.toLowerCase();
    return _tags!.any((t) {
      if (excludeId != null && t['id'] == excludeId) return false;
      return (t['name'] as String? ?? '').toLowerCase() == lower;
    });
  }

  void _showCreateDialog() {
    _showTagForm(
      title: 'Create Tag',
      initialColor: TagColorCache.presetColors.first.hex,
      onSave: (name, color) async {
        await getIt<Dio>().post<void>(
          '/api/tags',
          data: {'name': name, 'color': color},
        );
        TagColorCache.instance.put(name, color);
        await _load();
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> tag) {
    final id = tag['id'] as String? ?? '';
    final currentName = tag['name'] as String? ?? '';
    final currentColor = tag['color'] as String? ??
        TagColorCache.instance.hexFor(currentName);
    _showTagForm(
      title: 'Edit Tag',
      initialName: currentName,
      initialColor: currentColor,
      excludeId: id,
      onSave: (name, color) async {
        await getIt<Dio>().put<void>(
          '/api/tags/$id',
          data: {'name': name, 'color': color},
        );
        TagColorCache.instance.put(name, color);
        await _load();
      },
    );
  }

  void _showTagForm({
    required String title,
    required Future<void> Function(String name, String color) onSave,
    String initialName = '',
    String initialColor = '#3B82F6',
    String? excludeId,
  }) {
    final ctrl = TextEditingController(text: initialName);
    var selectedColor = initialColor;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final name = ctrl.text.trim();
          final isDup = name.isNotEmpty && _isDuplicate(name, excludeId: excludeId);
          final color = _parseHex(selectedColor);

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.headlineSmall),
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
                const SizedBox(height: 16),
                // Color picker
                Text('Color',
                    style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TagColorCache.presetColors.map((c) {
                    final isSelected = c.hex == selectedColor;
                    final parsed = _parseHex(c.hex);
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedColor = c.hex),
                      child: Tooltip(
                        message: c.name,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: parsed,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .onSurface,
                                    width: 2.5,
                                  )
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (name.isNotEmpty && !isDup) ...[
                  const SizedBox(height: 16),
                  Text('Preview',
                      style: Theme.of(ctx).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(children: [CrmTagChip(name: name, colorOverride: color)]),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isDup || name.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            await onSave(name, selectedColor);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          }
                        },
                  child: Text(initialName.isEmpty ? 'Create' : 'Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteTag(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text(
          'Delete "$name"? This will not remove the tag from existing records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
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
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tag = filtered![index];
                          final name = tag['name'] as String? ?? '';
                          final id = tag['id'] as String? ?? '';
                          final color = TagColorCache.instance.colorFor(name);

                          return ListTile(
                            leading: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(name),
                            subtitle: CrmTagChip(
                              name: name,
                              compact: true,
                            ),
                            onTap: () => _showEditDialog(tag),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 18),
                                  tooltip: 'Edit',
                                  onPressed: () => _showEditDialog(tag),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colorScheme.error,
                                  ),
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteTag(id, name),
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
