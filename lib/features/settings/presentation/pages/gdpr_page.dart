import 'dart:convert';

import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class GdprPage extends StatefulWidget {
  const GdprPage({super.key});

  @override
  State<GdprPage> createState() => _GdprPageState();
}

class _GdprPageState extends State<GdprPage> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  Map<String, dynamic>? _selectedContact;
  bool _processing = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final response = await getIt<ContactRemoteDataSource>()
          .getContacts(page: 1, perPage: 20);
      final q = query.toLowerCase();
      final filtered = response.items
          .where((c) {
            final name = '${c.firstName} ${c.lastName}'.toLowerCase();
            return name.contains(q) || c.email.toLowerCase().contains(q);
          })
          .map((c) => {
                'id': c.id,
                'name': '${c.firstName} ${c.lastName}'.trim(),
                'email': c.email,
              })
          .toList();
      if (mounted) setState(() => _results = filtered);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _exportData() async {
    if (_selectedContact == null) return;
    final id = _selectedContact!['id'] as String;
    setState(() => _processing = true);
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/gdpr/export/$id',
      );
      if (!mounted) return;

      // Show the exported data in a dialog.
      final data = response.data?['data'];
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Exported Data'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _hardDelete() async {
    if (_selectedContact == null) return;
    final contact = _selectedContact!;
    final name = contact['name'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permanently delete "$name"?'),
        content: const Text(
          'This will permanently delete this contact and ALL associated data '
          '(emails, notes, files, activity links). This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processing = true);
    try {
      await getIt<Dio>().delete<void>(
        '/api/gdpr/delete/${contact['id']}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name permanently deleted')),
        );
        setState(() {
          _selectedContact = null;
          _results = [];
          _searchCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Data Privacy (GDPR)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: cs.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hard delete permanently removes ALL data for a contact. '
                      'This action cannot be undone.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search
            Text('Search for a contact',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              onChanged: _search,
            ),
            const SizedBox(height: 8),

            // Search results
            if (_results.isNotEmpty)
              Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _results.map((c) {
                    final isSelected = _selectedContact?['id'] == c['id'];
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      leading: const Icon(Icons.person_outline, size: 20),
                      title: Text(c['name'] as String? ?? ''),
                      subtitle: Text(c['email'] as String? ?? ''),
                      onTap: () => setState(() => _selectedContact = c),
                    );
                  }).toList(),
                ),
              ),

            // Selected contact actions
            if (_selectedContact != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            _selectedContact!['name'] as String? ?? '',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        _selectedContact!['email'] as String? ?? '',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _processing ? null : _exportData,
                            icon: const Icon(Icons.download),
                            label: const Text('Export Data'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _processing ? null : _hardDelete,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Hard Delete'),
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.error,
                              foregroundColor: cs.onError,
                            ),
                          ),
                          if (_processing) ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
