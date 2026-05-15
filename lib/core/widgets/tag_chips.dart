import 'package:flutter/material.dart';

class TagChips extends StatelessWidget {
  const TagChips({
    required this.tags,
    this.onAdd,
    this.onRemove,
    super.key,
  });

  final List<String> tags;
  final VoidCallback? onAdd;
  final void Function(String tag)? onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final tag in tags)
          Chip(
            label: Text(tag),
            onDeleted: onRemove != null ? () => onRemove?.call(tag) : null,
            deleteIcon:
                onRemove != null ? const Icon(Icons.close, size: 18) : null,
          ),
        if (onAdd != null)
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            onPressed: onAdd,
          ),
      ],
    );
  }
}
