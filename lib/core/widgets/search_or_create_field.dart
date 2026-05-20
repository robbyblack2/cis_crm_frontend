import 'dart:async';

import 'package:flutter/material.dart';

/// A reusable search field that shows a "Create" prompt when no results match.
///
/// [T] is the type of the selected item (e.g., a Map or entity).
class SearchOrCreateField<T> extends StatefulWidget {
  const SearchOrCreateField({
    required this.label,
    required this.onSearch,
    required this.onSelected,
    required this.itemLabel,
    this.onCreateTapped,
    this.createEntityLabel = 'item',
    this.selectedItem,
    this.itemSubtitle,
    super.key,
  });

  /// Label for the text field.
  final String label;

  /// Called with the query string; returns a list of results.
  final Future<List<T>> Function(String query) onSearch;

  /// Called when a result is selected.
  final ValueChanged<T> onSelected;

  /// Extracts a display label from an item.
  final String Function(T item) itemLabel;

  /// Optional subtitle extractor.
  final String Function(T item)? itemSubtitle;

  /// Called when user taps "Create [query]". Receives the typed query.
  /// Should return the newly created item, or null if cancelled.
  final Future<T?> Function(String query)? onCreateTapped;

  /// Entity type label for the create button (e.g., "contact", "company").
  final String createEntityLabel;

  /// Currently selected item (to show as a chip).
  final T? selectedItem;

  @override
  State<SearchOrCreateField<T>> createState() => _SearchOrCreateFieldState<T>();
}

class _SearchOrCreateFieldState<T> extends State<SearchOrCreateField<T>> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<T> _results = [];
  bool _searching = false;
  bool _showResults = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay to allow tap on result to register
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showResults = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      try {
        final results = await widget.onSearch(query);
        if (mounted) {
          setState(() {
            _results = results;
            _searching = false;
            _showResults = true;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _results = [];
            _searching = false;
            _showResults = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected chip (if any)
        if (widget.selectedItem != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Chip(
              label: Text(widget.itemLabel(widget.selectedItem as T)),
              onDeleted: () {
                // Clear by re-selecting with a "null-like" approach
                _controller.clear();
                setState(() => _results = []);
              },
            ),
          ),

        // Search field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _onChanged,
        ),

        // Results dropdown
        if (_showResults && _controller.text.length >= 2) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: _results.isNotEmpty
                ? ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: colorScheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        dense: true,
                        title: Text(widget.itemLabel(item)),
                        subtitle: widget.itemSubtitle != null
                            ? Text(
                                widget.itemSubtitle!(item),
                                style: theme.textTheme.bodySmall,
                              )
                            : null,
                        onTap: () {
                          widget.onSelected(item);
                          _controller.text = widget.itemLabel(item);
                          setState(() => _showResults = false);
                          _focusNode.unfocus();
                        },
                      );
                    },
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No results found',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (widget.onCreateTapped != null)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.add_circle_outline,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            'Create "${_controller.text}"',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () async {
                            final query = _controller.text.trim();
                            setState(() => _showResults = false);
                            final created =
                                await widget.onCreateTapped!(query);
                            if (created != null && mounted) {
                              widget.onSelected(created);
                              _controller.text = widget.itemLabel(created);
                            }
                          },
                        ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}
