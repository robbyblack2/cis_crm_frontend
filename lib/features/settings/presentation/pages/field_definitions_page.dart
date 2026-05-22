import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class FieldDefinitionsPage extends StatefulWidget {
  const FieldDefinitionsPage({super.key});

  @override
  State<FieldDefinitionsPage> createState() => _FieldDefinitionsPageState();
}

class _FieldDefinitionsPageState extends State<FieldDefinitionsPage> {
  var _entityType = 'contact';
  List<Map<String, dynamic>>? _fields;
  bool _loading = true;

  final _entityTypes = [
    'contact',
    'company',
    'record',
    'subscription',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/fields',
        queryParameters: {'entity_type': _entityType},
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _fields = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _fields = []; _loading = false; });
    }
  }

  void _showCreateFieldDialog() {
    final nameCtrl = TextEditingController();
    var fieldType = 'text';
    var isRequired = false;
    final optionsCtrl = TextEditingController();

    final fieldTypes = [
      'text',
      'textarea',
      'number',
      'email',
      'phone',
      'url',
      'date',
      'currency',
      'dropdown',
      'address',
      'relation',
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 480),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Create Field'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
                actions: [
                  FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        final options = fieldType == 'dropdown'
                            ? optionsCtrl.text
                                .split(',')
                                .map((o) => o.trim())
                                .where((o) => o.isNotEmpty)
                                .toList()
                            : null;
                        await getIt<Dio>().post<void>(
                          '/api/fields',
                          data: {
                            'entity_type': _entityType,
                            'display_name': name,
                            'field_type': fieldType,
                            'is_required': isRequired,
                            if (options != null) 'options': options,
                          },
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
                  const SizedBox(width: 8),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Display name'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: fieldType,
                    decoration:
                        const InputDecoration(labelText: 'Field type'),
                    items: fieldTypes
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => fieldType = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Required'),
                    value: isRequired,
                    onChanged: (v) =>
                        setDialogState(() => isRequired = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (fieldType == 'dropdown') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: optionsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Options (comma-separated)',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteField(String fieldId) async {
    try {
      await getIt<Dio>().delete<void>('/api/fields/$fieldId');
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
      appBar: AppBar(
        title: const Text('Field Definitions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: _entityTypes
                  .map(
                    (t) => ButtonSegment(
                      value: t,
                      label: Text(
                        t[0].toUpperCase() + t.substring(1),
                      ),
                    ),
                  )
                  .toList(),
              selected: {_entityType},
              onSelectionChanged: (s) {
                setState(() => _entityType = s.first);
                _load();
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fields_fab',
        onPressed: _showCreateFieldDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _fields == null || _fields!.isEmpty
              ? EmptyState(
                  icon: Icons.text_fields,
                  title: 'No fields for $_entityType',
                  message: 'Tap + to create a custom field.',
                )
              : ListView.separated(
                  itemCount: _fields!.length,
                  padding: const EdgeInsets.all(8),
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final field = _fields![index];
                    final name =
                        field['display_name'] as String? ?? '';
                    final type =
                        field['field_type'] as String? ?? '';
                    final isSystem =
                        field['is_system'] as bool? ?? false;
                    final isReq =
                        field['is_required'] as bool? ?? false;

                    return ListTile(
                      leading: Icon(
                        _fieldIcon(type),
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(name),
                      subtitle: Text(
                        '$type${isReq ? ' · required' : ''}'
                        '${isSystem ? ' · system' : ''}',
                      ),
                      trailing: isSystem
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () => _deleteField(
                                field['id'] as String,
                              ),
                            ),
                    );
                  },
                ),
    );
  }

  IconData _fieldIcon(String type) {
    return switch (type) {
      'text' => Icons.text_fields,
      'textarea' => Icons.notes,
      'number' => Icons.numbers,
      'email' => Icons.email_outlined,
      'phone' => Icons.phone_outlined,
      'url' => Icons.link,
      'date' => Icons.calendar_today,
      'currency' => Icons.attach_money,
      'dropdown' => Icons.arrow_drop_down_circle_outlined,
      'address' => Icons.location_on_outlined,
      'relation' => Icons.people_outline,
      _ => Icons.text_fields,
    };
  }
}
