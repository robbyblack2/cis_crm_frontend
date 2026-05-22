import 'package:cis_crm/core/widgets/crm_tag_chip.dart';
import 'package:flutter/material.dart';

/// Reusable tag management card for contacts, companies, and any entity.
/// Shows current tags with delete buttons and an Add dropdown to pick
/// from available tags.
class EntityTagsCard extends StatelessWidget {
  const EntityTagsCard({
    super.key,
    required this.tags,
    required this.availableTags,
    required this.onTagsChanged,
    this.title = 'Tags',
  });

  final List<String> tags;
  final List<String> availableTags;
  final ValueChanged<List<String>> onTagsChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unassigned =
        availableTags.where((t) => !tags.contains(t)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...tags.map(
                  (tag) => CrmTagChip(
                    name: tag,
                    onDeleted: () {
                      final updated = tags.where((t) => t != tag).toList();
                      onTagsChanged(updated);
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Add tag',
                  offset: const Offset(0, 32),
                  onSelected: (tag) {
                    onTagsChanged([...tags, tag]);
                  },
                  itemBuilder: (_) => unassigned
                      .map((t) => PopupMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                CrmTagChip(name: t, compact: true),
                              ],
                            ),
                          ))
                      .toList(),
                  child: Chip(
                    avatar: const Icon(Icons.add, size: 14),
                    label: const Text('Add'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
