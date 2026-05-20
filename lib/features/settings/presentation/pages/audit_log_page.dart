import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/utils/name_resolver.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  List<Map<String, dynamic>>? _entries;
  bool _loading = true;
  String _search = '';
  String? _actionFilter;
  String? _entityTypeFilter;
  String _dateRange = 'all'; // 'all', 'today', '7d', '30d', 'custom'
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Pre-load names for resolution
    NameResolver.instance.loadUsers();
    NameResolver.instance.loadContacts();
    NameResolver.instance.loadCompanies();
    try {
      final response =
          await getIt<Dio>().get<Map<String, dynamic>>('/api/audit-log');
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _entries = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _entries = []; _loading = false; });
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at '
          '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return iso;
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 7) return _formatDateTime(iso);
      if (diff.inDays > 0) {
        return diff.inDays == 1 ? 'Yesterday' : '${diff.inDays} days ago';
      }
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return iso;
    }
  }

  String _humanAction(String action, String entityType) {
    final verb = switch (action.toLowerCase()) {
      'create' || 'created' => 'Created',
      'update' || 'updated' => 'Updated',
      'delete' || 'deleted' => 'Deleted',
      'move' || 'moved' => 'Moved',
      'login' => 'Logged in',
      'logout' => 'Logged out',
      'claim' || 'claimed' => 'Claimed',
      'assign' || 'assigned' => 'Assigned',
      _ => action,
    };
    final entity = entityType.isNotEmpty
        ? ' ${entityType.replaceAll('_', ' ')}'
        : '';
    return '$verb$entity';
  }

  Color _actionColor(String action) => switch (action.toLowerCase()) {
        'create' || 'created' => Colors.green,
        'update' || 'updated' => Colors.blue,
        'delete' || 'deleted' => Colors.red,
        'move' || 'moved' => Colors.orange,
        'login' => Colors.teal,
        'logout' => Colors.grey,
        _ => Colors.grey,
      };

  IconData _actionIcon(String action) => switch (action.toLowerCase()) {
        'create' || 'created' => Icons.add_circle_outline,
        'update' || 'updated' => Icons.edit_outlined,
        'delete' || 'deleted' => Icons.delete_outline,
        'move' || 'moved' => Icons.swap_horiz,
        'login' => Icons.login,
        'logout' => Icons.logout,
        'claim' || 'claimed' => Icons.person_add_alt_1,
        _ => Icons.history,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Apply filters
    var filtered = _entries ?? [];
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((e) {
        final action = (e['action'] as String? ?? '').toLowerCase();
        final entityType = (e['entity_type'] as String? ?? '').toLowerCase();
        final actor = (e['actor_email'] as String? ?? '').toLowerCase();
        return action.contains(q) ||
            entityType.contains(q) ||
            actor.contains(q);
      }).toList();
    }
    if (_actionFilter != null) {
      filtered = filtered
          .where(
            (e) =>
                (e['action'] as String? ?? '').toLowerCase() == _actionFilter,
          )
          .toList();
    }
    if (_entityTypeFilter != null) {
      filtered = filtered
          .where(
            (e) =>
                (e['entity_type'] as String? ?? '').toLowerCase() ==
                _entityTypeFilter,
          )
          .toList();
    }
    // Date range filter
    if (_dateRange != 'all') {
      final now = DateTime.now();
      DateTime? cutoff;
      switch (_dateRange) {
        case 'today':
          cutoff = DateTime(now.year, now.month, now.day);
        case '7d':
          cutoff = now.subtract(const Duration(days: 7));
        case '30d':
          cutoff = now.subtract(const Duration(days: 30));
        case 'custom':
          cutoff = _customFrom;
      }
      if (cutoff != null) {
        filtered = filtered.where((e) {
          final ts = e['created_at'] as String?;
          if (ts == null) return false;
          try {
            final dt = DateTime.parse(ts);
            if (dt.isBefore(cutoff!)) return false;
            if (_dateRange == 'custom' && _customTo != null) {
              final end = _customTo!.add(const Duration(days: 1));
              if (dt.isAfter(end)) return false;
            }
            return true;
          } catch (_) {
            return false;
          }
        }).toList();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Audit Log${_entries != null ? ' (${_entries!.length})' : ''}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(190),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search audit log...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(height: 8),
              // Action filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    _filterChip('All', null),
                    const SizedBox(width: 8),
                    _filterChip('Created', 'create'),
                    const SizedBox(width: 8),
                    _filterChip('Updated', 'update'),
                    const SizedBox(width: 8),
                    _filterChip('Deleted', 'delete'),
                    const SizedBox(width: 8),
                    _filterChip('Moved', 'move'),
                    const SizedBox(width: 8),
                    _filterChip('Login', 'login'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Date range filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    _dateChip('All time', 'all'),
                    const SizedBox(width: 8),
                    _dateChip('Today', 'today'),
                    const SizedBox(width: 8),
                    _dateChip('Last 7 days', '7d'),
                    const SizedBox(width: 8),
                    _dateChip('Last 30 days', '30d'),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(_dateRange == 'custom' && _customFrom != null
                          ? 'Custom: ${_customFrom!.day}/${_customFrom!.month}'
                              '${_customTo != null ? ' – ${_customTo!.day}/${_customTo!.month}' : ''}'
                          : 'Custom...'),
                      selected: _dateRange == 'custom',
                      onSelected: (_) async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _customFrom != null
                              ? DateTimeRange(
                                  start: _customFrom!,
                                  end: _customTo ?? DateTime.now(),
                                )
                              : null,
                        );
                        if (picked != null) {
                          setState(() {
                            _dateRange = 'custom';
                            _customFrom = picked.start;
                            _customTo = picked.end;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Entity type filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    _entityChip('All types', null),
                    const SizedBox(width: 8),
                    _entityChip('Contact', 'contact'),
                    const SizedBox(width: 8),
                    _entityChip('Record', 'record'),
                    const SizedBox(width: 8),
                    _entityChip('Pipeline', 'pipeline'),
                    const SizedBox(width: 8),
                    _entityChip('Company', 'company'),
                    const SizedBox(width: 8),
                    _entityChip('Task', 'task'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.history,
                  title: 'No audit log entries',
                  message: 'Activity will appear here as it happens.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final action = entry['action'] as String? ?? 'unknown';
                    final entityType =
                        entry['entity_type'] as String? ?? '';
                    final actorId = entry['actor_id'] as String?;
                    final actor = entry['actor_email'] as String? ??
                        entry['actor_name'] as String? ??
                        NameResolver.instance.userName(actorId) ??
                        actorId ??
                        '';
                    final ts = entry['created_at'] as String? ?? '';
                    final color = _actionColor(action);

                    return ListTile(
                      onTap: () => _showEntryDetail(context, entry),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(
                          _actionIcon(action),
                          color: color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _humanAction(action, entityType),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        [
                          if (actor.isNotEmpty) actor,
                          _relativeTime(ts),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                    );
                  },
                ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final isSelected = _actionFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _actionFilter = value),
    );
  }

  Widget _dateChip(String label, String value) {
    final isSelected = _dateRange == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _dateRange = value),
    );
  }

  Widget _entityChip(String label, String? value) {
    final isSelected = _entityTypeFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _entityTypeFilter = value),
    );
  }

  void _showEntryDetail(BuildContext context, Map<String, dynamic> entry) {
    final theme = Theme.of(context);
    final action = entry['action'] as String? ?? 'unknown';
    final entityType = entry['entity_type'] as String? ?? '';
    final entityId = entry['entity_id'] as String? ?? '';
    final actor = entry['actor_email'] as String? ??
        entry['actor_name'] as String? ??
        entry['actor_id'] as String? ??
        '';
    final ts = entry['created_at'] as String? ?? '';
    final changes = entry['changes'] as Map<String, dynamic>?;
    final metadata = entry['metadata'] as Map<String, dynamic>?;
    final color = _actionColor(action);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => Scaffold(
          appBar: AppBar(
            title: Text(_humanAction(action, entityType)),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                color.withValues(alpha: 0.12),
                            child: Icon(
                              _actionIcon(action),
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _humanAction(action, entityType),
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(ts),
                                  style:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _detailRow(theme, 'Action', action),
                      _detailRow(theme, 'Entity Type', entityType),
                      if (entityId.isNotEmpty) ...[
                        _detailRow(
                          theme,
                          'Entity',
                          _resolveEntityName(entityType, entityId),
                        ),
                      ],
                      _detailRow(
                        theme,
                        'Actor',
                        NameResolver.instance.userName(
                              entry['actor_id'] as String?,
                            ) ??
                            actor,
                      ),
                      _detailRow(theme, 'Timestamp', _formatDateTime(ts)),
                    ],
                  ),
                ),
              ),

              // Changes card
              if (changes != null && changes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Changes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(height: 24),
                        ...changes.entries.map(
                          (e) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    e.key,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${e.value}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Metadata card
              if (metadata != null && metadata.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metadata',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(height: 24),
                        ...metadata.entries.map(
                          (e) => _detailRow(theme, e.key, '${e.value}'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _resolveEntityName(String entityType, String entityId) {
    final resolver = NameResolver.instance;
    final name = switch (entityType.toLowerCase()) {
      'contact' => resolver.contactName(entityId),
      'company' => resolver.companyName(entityId),
      'user' => resolver.userName(entityId),
      _ => null,
    };
    return name ?? entityId;
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
