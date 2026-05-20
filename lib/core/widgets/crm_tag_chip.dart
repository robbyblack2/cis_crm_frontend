import 'package:cis_crm/core/utils/tag_color_cache.dart';
import 'package:flutter/material.dart';

/// The one and only tag chip widget used everywhere in the app.
///
/// Reads color from [TagColorCache] (server color → hash fallback).
class CrmTagChip extends StatelessWidget {
  const CrmTagChip({
    required this.name,
    this.onDeleted,
    this.compact = true,
    super.key,
  });

  final String name;
  final VoidCallback? onDeleted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = TagColorCache.instance.colorFor(name);
    final theme = Theme.of(context);

    return Chip(
      label: Text(name),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontSize: compact ? 11 : null,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      padding: compact ? EdgeInsets.zero : null,
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      deleteIcon: onDeleted != null
          ? Icon(Icons.close, size: 14, color: color)
          : null,
      onDeleted: onDeleted,
    );
  }
}
