import 'package:flutter/material.dart';

/// A reusable slide-in filter panel for list pages.
///
/// Slides in from the right. Supports checkbox groups, tag pickers,
/// date range presets, searchable dropdowns, and radio groups.
class FilterSidebar extends StatelessWidget {
  const FilterSidebar({
    required this.sections,
    required this.onClearAll,
    this.resultCount,
    this.totalCount,
    super.key,
  });

  final List<FilterSection> sections;
  final VoidCallback onClearAll;
  final int? resultCount;
  final int? totalCount;

  int get activeFilterCount =>
      sections.where((s) => s.hasActiveFilters).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (activeFilterCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (activeFilterCount > 0)
                  TextButton(
                    onPressed: onClearAll,
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (int i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 20),
                  sections[i],
                ],
              ],
            ),
          ),

          // Footer with result count
          if (resultCount != null || totalCount != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                resultCount != null && totalCount != null
                    ? 'Showing $resultCount of $totalCount'
                    : resultCount != null
                        ? '$resultCount results'
                        : '$totalCount total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A toggle button for the AppBar that shows active filter count.
class FilterToggleButton extends StatelessWidget {
  const FilterToggleButton({
    required this.activeCount,
    required this.onPressed,
    this.isOpen = false,
    super.key,
  });

  final int activeCount;
  final VoidCallback onPressed;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: activeCount > 0,
      label: Text('$activeCount'),
      child: IconButton(
        icon: Icon(isOpen ? Icons.filter_list_off : Icons.filter_list),
        tooltip: isOpen ? 'Hide filters' : 'Show filters',
        onPressed: onPressed,
      ),
    );
  }
}

/// Active filter chips displayed below the search bar.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    required this.filters,
    super.key,
  });

  final List<ActiveFilter> filters;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: filters
            .map(
              (f) => Chip(
                label: Text(f.label),
                onDeleted: f.onRemove,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(),
      ),
    );
  }
}

class ActiveFilter {
  const ActiveFilter({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;
}

// ──────────────────────────────────────────────────────────────────
// Filter section types
// ──────────────────────────────────────────────────────────────────

abstract class FilterSection extends StatelessWidget {
  const FilterSection({super.key});

  bool get hasActiveFilters;

  /// Checkbox group (multi-select).
  static Widget checkboxGroup({
    required String title,
    required List<FilterOption> options,
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return _CheckboxGroupSection(
      title: title,
      options: options,
      selected: selected,
      onChanged: onChanged,
    );
  }

  /// Date range with presets.
  static Widget dateRange({
    required String title,
    required String selectedPreset,
    required ValueChanged<String> onPresetChanged,
    DateTime? customFrom,
    DateTime? customTo,
    ValueChanged<DateTimeRange>? onCustomChanged,
  }) {
    return _DateRangeSection(
      title: title,
      selectedPreset: selectedPreset,
      onPresetChanged: onPresetChanged,
      customFrom: customFrom,
      customTo: customTo,
      onCustomChanged: onCustomChanged,
    );
  }

  /// Radio group (single select).
  static Widget radioGroup({
    required String title,
    required List<FilterOption> options,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    return _RadioGroupSection(
      title: title,
      options: options,
      selected: selected,
      onChanged: onChanged,
    );
  }
}

class FilterOption {
  const FilterOption({
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final Color? color;
}

// ──────────────────────────────────────────────────────────────────
// Implementations
// ──────────────────────────────────────────────────────────────────

class _CheckboxGroupSection extends FilterSection {
  const _CheckboxGroupSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<FilterOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  bool get hasActiveFilters => selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        ...options.map((o) {
          final isChecked = selected.contains(o.value);
          return InkWell(
            onTap: () {
              final updated = Set<String>.from(selected);
              if (isChecked) {
                updated.remove(o.value);
              } else {
                updated.add(o.value);
              }
              onChanged(updated);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isChecked,
                      onChanged: (_) {
                        final updated = Set<String>.from(selected);
                        if (isChecked) {
                          updated.remove(o.value);
                        } else {
                          updated.add(o.value);
                        }
                        onChanged(updated);
                      },
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (o.color != null) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: o.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      o.label,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _DateRangeSection extends FilterSection {
  const _DateRangeSection({
    required this.title,
    required this.selectedPreset,
    required this.onPresetChanged,
    this.customFrom,
    this.customTo,
    this.onCustomChanged,
  });

  final String title;
  final String selectedPreset;
  final ValueChanged<String> onPresetChanged;
  final DateTime? customFrom;
  final DateTime? customTo;
  final ValueChanged<DateTimeRange>? onCustomChanged;

  @override
  bool get hasActiveFilters => selectedPreset != 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _presetChip(context, 'All time', 'all'),
            _presetChip(context, 'Today', 'today'),
            _presetChip(context, '7 days', '7d'),
            _presetChip(context, '30 days', '30d'),
          ],
        ),
        if (onCustomChanged != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range, size: 16),
            label: Text(
              selectedPreset == 'custom' && customFrom != null
                  ? '${customFrom!.month}/${customFrom!.day} – '
                      '${customTo?.month ?? ''}/${customTo?.day ?? ''}'
                  : 'Custom range',
              style: theme.textTheme.labelSmall,
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                onCustomChanged!(picked);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _presetChip(BuildContext context, String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedPreset == value,
      onSelected: (_) => onPresetChanged(value),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RadioGroupSection extends FilterSection {
  const _RadioGroupSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<FilterOption> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  bool get hasActiveFilters => selected != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        ...options.map(
          (o) => RadioListTile<String>(
            title: Text(o.label, style: theme.textTheme.bodySmall),
            value: o.value,
            groupValue: selected,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}
