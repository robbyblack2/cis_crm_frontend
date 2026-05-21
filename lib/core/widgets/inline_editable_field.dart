import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The type of inline editor to show on double-tap.
enum InlineEditMode { text, dropdown, search }

/// A field that displays a value and transforms into an inline editor on
/// double-tap. Supports text input, dropdown selection, and search-with-
/// autocomplete modes.
class InlineEditableField<T> extends StatefulWidget {
  const InlineEditableField({
    required this.displayWidget,
    required this.editMode,
    required this.onSave,
    this.currentValue,
    this.emptyPlaceholder,
    this.textValue,
    this.dropdownItems,
    this.dropdownValue,
    this.onSearch,
    this.searchItemLabel,
    this.searchItemSubtitle,
    this.onCreateTapped,
    this.createEntityLabel = 'item',
    this.readOnly = false,
    super.key,
  });

  /// Widget shown in display (non-editing) mode.
  final Widget displayWidget;

  /// Which edit mode to enter on double-tap.
  final InlineEditMode editMode;

  /// Called when the user confirms a new value.
  final ValueChanged<T> onSave;

  /// The current raw value (used for pre-filling text fields).
  final T? currentValue;

  /// Current text value for text mode pre-fill.
  final String? textValue;

  /// Placeholder when value is empty.
  final String? emptyPlaceholder;

  /// Items for dropdown mode.
  final List<DropdownMenuItem<T>>? dropdownItems;

  /// Current dropdown value.
  final T? dropdownValue;

  /// Search function for search mode.
  final Future<List<T>> Function(String query)? onSearch;

  /// Extracts display label from a search result.
  final String Function(T item)? searchItemLabel;

  /// Extracts subtitle from a search result.
  final String Function(T item)? searchItemSubtitle;

  /// Called when "Create [query]" is tapped.
  final Future<T?> Function(String query)? onCreateTapped;

  /// Entity label for create button (e.g. "contact").
  final String createEntityLabel;

  /// Whether this field is read-only (no double-tap).
  final bool readOnly;

  @override
  State<InlineEditableField<T>> createState() => _InlineEditableFieldState<T>();
}

class _InlineEditableFieldState<T> extends State<InlineEditableField<T>> {
  bool _editing = false;

  // Text mode
  late final TextEditingController _textCtrl;

  // Search mode
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  List<T> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.textValue ?? '');
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _enterEditMode() {
    if (widget.readOnly) return;
    setState(() {
      _editing = true;
      if (widget.editMode == InlineEditMode.text) {
        _textCtrl.text = widget.textValue ?? '';
      } else if (widget.editMode == InlineEditMode.search) {
        _searchCtrl.clear();
        _searchResults = [];
      }
    });
  }

  void _cancel() {
    setState(() => _editing = false);
  }

  void _saveText() {
    final value = _textCtrl.text.trim();
    if (value != (widget.textValue ?? '')) {
      widget.onSave(value as T);
    }
    setState(() => _editing = false);
  }

  void _saveDropdown(T? value) {
    if (value != null) {
      widget.onSave(value);
    }
    setState(() => _editing = false);
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      try {
        final results = await widget.onSearch!(query);
        if (mounted) setState(() => _searchResults = results);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return _DisplayMode(
        displayWidget: widget.displayWidget,
        emptyPlaceholder: widget.emptyPlaceholder,
        currentValue: widget.currentValue,
        readOnly: widget.readOnly,
        onDoubleTap: _enterEditMode,
      );
    }

    return switch (widget.editMode) {
      InlineEditMode.text => _buildTextEditor(context),
      InlineEditMode.dropdown => _buildDropdownEditor(context),
      InlineEditMode.search => _buildSearchEditor(context),
    };
  }

  Widget _buildTextEditor(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onSubmitted: (_) => _saveText(),
            onTapOutside: (_) => _saveText(),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.check, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: _saveText,
          tooltip: 'Save',
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: _cancel,
          tooltip: 'Cancel',
        ),
      ],
    );
  }

  Widget _buildDropdownEditor(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<T>(
            value: widget.dropdownValue,
            autofocus: true,
            isDense: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            items: widget.dropdownItems,
            onChanged: _saveDropdown,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: _cancel,
          tooltip: 'Cancel',
        ),
      ],
    );
  }

  Widget _buildSearchEditor(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: 'Search...',
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: _cancel,
                        ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ],
        ),
        if (_searchResults.isNotEmpty || _searchCtrl.text.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                ..._searchResults.map((item) {
                  final label = widget.searchItemLabel?.call(item) ?? '$item';
                  final subtitle = widget.searchItemSubtitle?.call(item);
                  return ListTile(
                    dense: true,
                    title: Text(label, style: theme.textTheme.bodySmall),
                    subtitle: subtitle != null
                        ? Text(subtitle,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant))
                        : null,
                    onTap: () {
                      widget.onSave(item);
                      setState(() => _editing = false);
                    },
                  );
                }),
                if (widget.onCreateTapped != null &&
                    _searchCtrl.text.isNotEmpty &&
                    _searchResults.isEmpty)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.add, size: 16, color: cs.primary),
                    title: Text(
                      'Create "${_searchCtrl.text}"',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.primary),
                    ),
                    onTap: () async {
                      final created =
                          await widget.onCreateTapped!(_searchCtrl.text);
                      if (created != null && mounted) {
                        widget.onSave(created);
                        setState(() => _editing = false);
                      }
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Display mode with hover pencil icon and double-tap trigger.
class _DisplayMode<T> extends StatefulWidget {
  const _DisplayMode({
    required this.displayWidget,
    required this.onDoubleTap,
    this.emptyPlaceholder,
    this.currentValue,
    this.readOnly = false,
  });

  final Widget displayWidget;
  final VoidCallback onDoubleTap;
  final String? emptyPlaceholder;
  final T? currentValue;
  final bool readOnly;

  @override
  State<_DisplayMode<T>> createState() => _DisplayModeState<T>();
}

class _DisplayModeState<T> extends State<_DisplayMode<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEmpty = widget.currentValue == null ||
        (widget.currentValue is String &&
            (widget.currentValue as String).isEmpty);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.readOnly
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onDoubleTap: widget.readOnly ? null : widget.onDoubleTap,
        child: Row(
          children: [
            Expanded(
              child: isEmpty && widget.emptyPlaceholder != null
                  ? Text(
                      widget.emptyPlaceholder!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : widget.displayWidget,
            ),
            if (_hovered && !widget.readOnly)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.edit,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
