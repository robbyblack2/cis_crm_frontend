import 'dart:async';

import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/network/web_socket_cubit.dart';
import 'package:cis_crm/core/network/web_socket_event.dart';
import 'package:cis_crm/core/responsive/breakpoints.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/pages/pipeline_management_page.dart';
import 'package:cis_crm/core/utils/name_resolver.dart';
import 'package:cis_crm/core/widgets/search_or_create_field.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/models/company_model.dart';
import 'package:cis_crm/features/contacts/data/models/contact_model.dart';
import 'package:cis_crm/features/pipeline/presentation/pages/pipeline_settings_page.dart';
import 'package:cis_crm/features/pipeline/presentation/pages/record_detail_page.dart';
import 'package:cis_crm/features/pipeline/presentation/widgets/stage_column.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PipelinePage extends StatelessWidget {
  const PipelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PipelineBloc>(
          create: (_) =>
              getIt<PipelineBloc>()..add(const PipelineLoadRequested()),
        ),
        BlocProvider<RecordBloc>(
          create: (_) => getIt<RecordBloc>()..add(const RecordLoadRequested()),
        ),
      ],
      child: const _PipelineView(),
    );
  }
}

class _PipelineView extends StatefulWidget {
  const _PipelineView();

  @override
  State<_PipelineView> createState() => _PipelineViewState();
}

/// Event types that should trigger a record reload.
const _recordEventTypes = {
  'record.created',
  'record.updated',
  'record.moved',
};

class _PipelineViewState extends State<_PipelineView> {
  StreamSubscription<WebSocketEvent>? _wsSub;
  String? _subscribedChannel;

  @override
  void dispose() {
    _unsubscribeChannel();
    _wsSub?.cancel();
    super.dispose();
  }

  void _subscribeToChannel(String pipelineId) {
    final channel = 'pipeline:$pipelineId';
    if (_subscribedChannel == channel) return;

    _unsubscribeChannel();
    _subscribedChannel = channel;

    final wsCubit = context.read<WebSocketCubit>()
      ..subscribe(channel);

    _wsSub?.cancel();
    _wsSub = wsCubit.events.listen((event) {
      if (_recordEventTypes.contains(event.type) && mounted) {
        context.read<RecordBloc>().add(const RecordLoadRequested());
      }
    });
  }

  void _unsubscribeChannel() {
    if (_subscribedChannel != null) {
      try {
        context.read<WebSocketCubit>().unsubscribe(_subscribedChannel!);
      } catch (_) {
        // Context may not be valid during dispose.
      }
      _subscribedChannel = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PipelineBloc, PipelineState>(
      listener: (context, state) {
        if (state is PipelineLoaded && state.pipelines.isNotEmpty) {
          final firstPipeline = state.pipelines.first;
          if (state.kanbanPipeline == null) {
            context.read<PipelineBloc>().add(
                  PipelineKanbanRequested(pipelineId: firstPipeline.id),
                );
          }
          // Subscribe to the active pipeline's WebSocket channel.
          final activePipelineId =
              state.kanbanPipeline?.id ?? firstPipeline.id;
          _subscribeToChannel(activePipelineId);
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        return switch (state) {
          PipelineInitial() =>
            PageLoading(label: l10n.pipelineInitializing),
          PipelineLoading() => PageLoading(label: l10n.pipelineLoading),
          PipelineError(:final message) => PageError(
              title: l10n.failedToLoadPipelines,
              message: message,
              onRetry: () => context
                  .read<PipelineBloc>()
                  .add(const PipelineLoadRequested()),
            ),
          PipelineLoaded() => _LoadedPipelineView(state: state),
        };
      },
    );
  }
}

class _LoadedPipelineView extends StatefulWidget {
  const _LoadedPipelineView({required this.state});

  final PipelineLoaded state;

  @override
  State<_LoadedPipelineView> createState() => _LoadedPipelineViewState();
}

class _LoadedPipelineViewState extends State<_LoadedPipelineView> {
  bool _listView = false;

  PipelineLoaded get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final stages = (state.kanbanStages ?? <Stage>[]).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final activePipelines = state.pipelines.where((p) => p.isActive).toList();
    final currentName =
        state.kanbanPipeline?.name ?? activePipelines.firstOrNull?.name ?? 'Pipeline';

    return Scaffold(
      appBar: AppBar(
        title: activePipelines.length > 1
            ? DropdownButton<String>(
                value: state.kanbanPipeline?.id,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.arrow_drop_down),
                style: Theme.of(context).textTheme.titleLarge,
                items: activePipelines
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id != null) {
                    context
                        .read<PipelineBloc>()
                        .add(PipelineKanbanRequested(pipelineId: id));
                  }
                },
              )
            : Text(currentName),
        actions: [
          IconButton(
            icon: Icon(
              _listView ? Icons.view_kanban : Icons.view_list,
            ),
            tooltip: _listView ? 'Board view' : 'List view',
            onPressed: () => setState(() => _listView = !_listView),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Manage Pipelines',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: context.read<PipelineBloc>(),
                    child: const PipelineManagementPage(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pipeline settings',
            onPressed: () {
              final pid =
                  state.kanbanPipeline?.id ?? state.pipelines.firstOrNull?.id;
              final pname = state.kanbanPipeline?.name ??
                  state.pipelines.firstOrNull?.name ??
                  'Pipeline';
              if (pid != null) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PipelineSettingsPage(
                      pipelineId: pid,
                      pipelineName: pname,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<RecordBloc, RecordState>(
        builder: (context, recordState) {
          return switch (recordState) {
            RecordInitial() => const Center(
                child: CircularProgressIndicator(),
              ),
            RecordLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            RecordError(:final message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<RecordBloc>()
                          .add(const RecordLoadRequested()),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
            RecordLoaded(:final records) => _listView
                ? _RecordListView(
                    stages: stages,
                    records: records,
                  )
                : _KanbanBoard(
                    stages: stages,
                    records: records,
                    pipelineId: state.kanbanPipeline?.id ?? '',
                  ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'pipeline_fab',
        onPressed: () => _showCreateRecordDialog(context),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.newRecord),
        tooltip: AppLocalizations.of(context)!.addNewRecord,
      ),
    );
  }

  void _showCreateRecordDialog(BuildContext context) {
    final recordBloc = context.read<RecordBloc>();
    final stages = (state.kanbanStages ?? <Stage>[]).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    if (stages.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateRecordSheet(
        stages: stages,
        pipelineId: state.kanbanPipeline?.id ?? '',
        recordBloc: recordBloc,
      ),
    );
  }
}

class _CreateRecordSheet extends StatefulWidget {
  const _CreateRecordSheet({
    required this.stages,
    required this.pipelineId,
    required this.recordBloc,
  });

  final List<Stage> stages;
  final String pipelineId;
  final RecordBloc recordBloc;

  @override
  State<_CreateRecordSheet> createState() => _CreateRecordSheetState();
}

class _CreateRecordSheetState extends State<_CreateRecordSheet> {
  final _titleCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  late String _selectedStageId;

  String? _selectedContactId;
  Map<String, dynamic>? _selectedContact;
  String? _selectedCompanyId;
  Map<String, dynamic>? _selectedCompany;

  @override
  void initState() {
    super.initState();
    _selectedStageId = widget.stages.first.id;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _searchContacts(String query) async {
    final response = await getIt<ContactRemoteDataSource>()
        .getContacts(page: 1, perPage: 10);
    final q = query.toLowerCase();
    return response.items
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
  }

  Future<List<Map<String, dynamic>>> _searchCompanies(String query) async {
    final companies =
        await getIt<CompanyRemoteDataSource>().getCompanies();
    return companies
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .map((c) => {'id': c.id, 'name': c.name})
        .toList();
  }

  Future<Map<String, dynamic>?> _createContact(String query) async {
    final hints = QueryParser.parseContactQuery(query);
    final firstCtrl =
        TextEditingController(text: hints.firstName ?? '');
    final lastCtrl =
        TextEditingController(text: hints.lastName ?? '');
    final emailCtrl =
        TextEditingController(text: hints.email ?? '');
    final phoneCtrl =
        TextEditingController(text: hints.phone ?? '');

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quick Add Contact',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: firstCtrl,
                decoration: const InputDecoration(
                  labelText: 'First name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lastCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final first = firstCtrl.text.trim();
                  if (first.isEmpty) return;
                  try {
                    final contact = ContactModel(
                      id: '',
                      firstName: first,
                      lastName: lastCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isNotEmpty
                          ? phoneCtrl.text.trim()
                          : null,
                      status: 'lead',
                      tags: const [],
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    final created = await getIt<ContactRemoteDataSource>()
                        .createContact(contact);
                    if (ctx.mounted) {
                      Navigator.pop(ctx, {
                        'id': created.id,
                        'name':
                            '${created.firstName} ${created.lastName}'.trim(),
                        'email': created.email,
                      });
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create Contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _createCompany(String query) async {
    final hints = QueryParser.parseCompanyQuery(query);
    final nameCtrl = TextEditingController(text: hints.name ?? '');
    final websiteCtrl = TextEditingController(text: hints.domain ?? '');
    final industryCtrl = TextEditingController();

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quick Add Company',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: websiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: industryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Industry',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  try {
                    final company = CompanyModel(
                      id: '',
                      name: name,
                      domain: websiteCtrl.text.trim().isNotEmpty
                          ? websiteCtrl.text.trim()
                          : null,
                      industry: industryCtrl.text.trim().isNotEmpty
                          ? industryCtrl.text.trim()
                          : null,
                      tags: const [],
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    final created = await getIt<CompanyRemoteDataSource>()
                        .createCompany(company);
                    if (ctx.mounted) {
                      Navigator.pop(ctx, {
                        'id': created.id,
                        'name': created.name,
                      });
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create Company'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    widget.recordBloc.add(
      RecordCreateRequested(
        pipelineId: widget.pipelineId,
        stageId: _selectedStageId,
        title: title,
        source: RecordSource.manual,
        contactId: _selectedContactId,
        companyId: _selectedCompanyId,
        tags: tags,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.newRecord,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),

              // ── Title ──
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  hintText: l10n.enterRecordTitle,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // ── Stage ──
              DropdownButtonFormField<String>(
                initialValue: _selectedStageId,
                decoration: InputDecoration(
                  labelText: l10n.stage,
                  border: const OutlineInputBorder(),
                ),
                items: widget.stages
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedStageId = v);
                },
              ),
              const SizedBox(height: 24),

              // ── Contact search ──
              Text(
                l10n.contact,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SearchOrCreateField<Map<String, dynamic>>(
                label: 'Search contacts...',
                onSearch: _searchContacts,
                itemLabel: (c) => c['name'] as String? ?? '',
                itemSubtitle: (c) => c['email'] as String? ?? '',
                createEntityLabel: 'contact',
                selectedItem: _selectedContact,
                onSelected: (c) => setState(() {
                  _selectedContactId = c['id'] as String?;
                  _selectedContact = c;
                }),
                onCleared: () => setState(() {
                  _selectedContactId = null;
                  _selectedContact = null;
                }),
                onCreateTapped: _createContact,
              ),
              const SizedBox(height: 16),

              // ── Company search ──
              Text(
                l10n.contactCompany,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SearchOrCreateField<Map<String, dynamic>>(
                label: 'Search companies...',
                onSearch: _searchCompanies,
                itemLabel: (c) => c['name'] as String? ?? '',
                createEntityLabel: 'company',
                selectedItem: _selectedCompany,
                onSelected: (c) => setState(() {
                  _selectedCompanyId = c['id'] as String?;
                  _selectedCompany = c;
                }),
                onCleared: () => setState(() {
                  _selectedCompanyId = null;
                  _selectedCompany = null;
                }),
                onCreateTapped: _createCompany,
              ),
              const SizedBox(height: 16),

              // ── Tags ──
              TextField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'Comma-separated (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.create),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordListView extends StatefulWidget {
  const _RecordListView({
    required this.stages,
    required this.records,
  });

  final List<Stage> stages;
  final List<PipelineRecord> records;

  @override
  State<_RecordListView> createState() => _RecordListViewState();
}

class _RecordListViewState extends State<_RecordListView> {
  String _sortColumn = 'stage';
  bool _sortAsc = true;

  Stage? _stageForRecord(PipelineRecord record) {
    return widget.stages.cast<Stage?>().firstWhere(
          (s) => s!.id == record.stageId,
          orElse: () => null,
        );
  }

  Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Color(int.tryParse(colorStr) ?? 0xFF9E9E9E);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  List<PipelineRecord> get _sortedRecords {
    final sorted = List<PipelineRecord>.from(widget.records);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'title':
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'stage':
          final sa = _stageForRecord(a)?.position ?? 999;
          final sb = _stageForRecord(b)?.position ?? 999;
          cmp = sa.compareTo(sb);
        case 'created':
          cmp = a.createdAt.compareTo(b.createdAt);
        case 'updated':
          cmp = a.updatedAt.compareTo(b.updatedAt);
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });
    return sorted;
  }

  void _toggleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAsc = !_sortAsc;
      } else {
        _sortColumn = column;
        _sortAsc = true;
      }
    });
  }

  Widget _headerCell(String label, String column, {int flex = 2}) {
    final isActive = _sortColumn == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _toggleSort(column),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (isActive)
              Icon(
                _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sorted = _sortedRecords;

    return Column(
      children: [
        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20), // stage dot space
              const SizedBox(width: 8),
              _headerCell('Title', 'title', flex: 3),
              _headerCell('Stage', 'stage'),
              _headerCell('Contact', 'contact'),
              _headerCell('Owner', 'owner'),
              _headerCell('Tags', 'tags'),
              _headerCell('Created', 'created'),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final record = sorted[index];
              final stage = _stageForRecord(record);
              final stageColor =
                  stage != null ? _parseColor(stage.color) : Colors.grey;

              return InkWell(
                onTap: () {
                  final pipelineBloc = context.read<PipelineBloc>();
                  final recordBloc = context.read<RecordBloc>();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider<PipelineBloc>.value(
                              value: pipelineBloc),
                          BlocProvider<RecordBloc>.value(
                              value: recordBloc),
                        ],
                        child: RecordDetailPage(recordId: record.id),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Stage color dot
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: stageColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Title
                      Expanded(
                        flex: 3,
                        child: Text(
                          record.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Stage name
                      Expanded(
                        flex: 2,
                        child: Text(
                          stage?.name ?? '—',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Contact
                      Expanded(
                        flex: 2,
                        child: record.contactId != null
                            ? ResolvedName(
                                id: record.contactId,
                                type: 'contact',
                                style: theme.textTheme.bodySmall,
                              )
                            : Text(
                                '—',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      // Owner
                      Expanded(
                        flex: 2,
                        child: record.ownerId != null
                            ? ResolvedName(
                                id: record.ownerId,
                                type: 'user',
                                style: theme.textTheme.bodySmall,
                              )
                            : Text(
                                '—',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      // Tags
                      Expanded(
                        flex: 2,
                        child: record.tags.isNotEmpty
                            ? Wrap(
                                spacing: 4,
                                children: record.tags.take(2).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  );
                                }).toList(),
                              )
                            : const SizedBox.shrink(),
                      ),
                      // Created
                      Expanded(
                        flex: 2,
                        child: Tooltip(
                          message: record.createdAt.toIso8601String(),
                          child: Text(
                            _timeAgo(record.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    required this.stages,
    required this.records,
    required this.pipelineId,
  });

  final List<Stage> stages;
  final List<PipelineRecord> records;
  final String pipelineId;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return EmptyState(
        icon: Icons.view_kanban_outlined,
        title: l10n.noStagesConfigured,
        message: l10n.noStagesConfiguredMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final windowSize = windowSizeFor(constraints.maxWidth);
        final columnWidth = switch (windowSize) {
          WindowSize.compact => 280.0,
          WindowSize.medium => 300.0,
          WindowSize.expanded => 320.0,
        };

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                SizedBox(
                  width: columnWidth,
                  height: constraints.maxHeight - 32,
                  child: StageColumn(
                    stage: stages[i],
                    records: records
                        .where((r) => r.stageId == stages[i].id)
                        .toList(),
                    onRecordTap: (record) => _navigateToDetail(
                      context,
                      record,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, PipelineRecord record) {
    final pipelineBloc = context.read<PipelineBloc>();
    final recordBloc = context.read<RecordBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<PipelineBloc>.value(value: pipelineBloc),
            BlocProvider<RecordBloc>.value(value: recordBloc),
          ],
          child: RecordDetailPage(recordId: record.id),
        ),
      ),
    );
  }
}
