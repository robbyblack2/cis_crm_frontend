import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/filter_sidebar.dart';
import 'package:cis_crm/core/widgets/search_or_create_field.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/models/company_model.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contact_form_cubit.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:cis_crm/features/contacts/presentation/pages/company_detail_page.dart';
import 'package:cis_crm/features/contacts/presentation/pages/contact_detail_page.dart';
import 'package:cis_crm/features/contacts/presentation/widgets/company_tile.dart';
import 'package:cis_crm/features/contacts/presentation/widgets/contact_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContactsBloc>()..add(const ContactsLoadRequested()),
      child: const _ContactsTabView(),
    );
  }
}

class _ContactsTabView extends StatelessWidget {
  const _ContactsTabView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 1,
            child: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.person), text: 'Contacts'),
                Tab(icon: Icon(Icons.business), text: 'Companies'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ContactsView(),
                _CompaniesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsView extends StatefulWidget {
  const _ContactsView();

  @override
  State<_ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<_ContactsView> {
  bool _sidebarOpen = false;
  Set<String> _statusFilter = {};
  Set<String> _tagFilter = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Compute active filter count for badge
    var activeCount = 0;
    if (_statusFilter.isNotEmpty) activeCount++;
    if (_tagFilter.isNotEmpty) activeCount++;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactsTitle),
        actions: [
          FilterToggleButton(
            activeCount: activeCount,
            isOpen: _sidebarOpen,
            onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Google Contacts',
            onPressed: () => _triggerSync(context),
          ),
          IconButton(
            icon: const Icon(Icons.merge_type),
            tooltip: 'Merge contacts',
            onPressed: () => _showMergeDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<ContactsBloc, ContactsState>(
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType || previous != current,
        builder: (context, state) {
          final listContent = switch (state) {
            ContactsInitial() || ContactsLoading() => const Center(
                child: CircularProgressIndicator(),
              ) as Widget,
            ContactsLoaded(:final contacts) => contacts.isEmpty
                ? EmptyState(
                    icon: Icons.contacts_outlined,
                    title: l10n.contactsEmpty,
                    message: l10n.contactsEmptyAction,
                    action: FilledButton.icon(
                      onPressed: () => _addContact(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addContact),
                    ),
                  )
                : _ContactsList(
                    state: state,
                    statusFilter: _statusFilter,
                    tagFilter: _tagFilter,
                  ),
            ContactsError(:final failure) => PageError(
                title: l10n.failedToLoadContacts,
                message: failure.message,
                onRetry: () => context
                    .read<ContactsBloc>()
                    .add(const ContactsLoadRequested()),
              ),
          };

          // Build sidebar sections from loaded data
          final allStatuses = <String>[];
          final allTags = <String>[];
          int totalCount = 0;
          if (state is ContactsLoaded) {
            allStatuses.addAll(
              state.contacts.map((c) => c.status).toSet().toList()..sort(),
            );
            allTags.addAll(
              state.contacts.expand((c) => c.tags).toSet().toList()..sort(),
            );
            totalCount = state.contacts.length;
          }

          return Row(
            children: [
              Expanded(child: listContent),
              if (_sidebarOpen)
                FilterSidebar(
                  totalCount: totalCount,
                  onClearAll: () => setState(() {
                    _statusFilter = {};
                    _tagFilter = {};
                  }),
                  sections: [
                    FilterSection.checkboxGroup(
                      title: 'Status',
                      options: allStatuses
                          .map((s) => FilterOption(value: s, label: s))
                          .toList(),
                      selected: _statusFilter,
                      onChanged: (v) => setState(() => _statusFilter = v),
                    ),
                    FilterSection.checkboxGroup(
                      title: 'Tags',
                      options: allTags
                          .map((t) => FilterOption(value: t, label: t))
                          .toList(),
                      selected: _tagFilter,
                      onChanged: (v) => setState(() => _tagFilter = v),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'contacts_fab',
        tooltip: l10n.addContactTooltip,
        onPressed: () => _addContact(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _triggerSync(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing Google Contacts...')),
    );
    try {
      await getIt<Dio>().post<void>('/api/contacts/sync');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync complete')),
        );
        context.read<ContactsBloc>().add(const ContactsLoadRequested());
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  void _openSearch(BuildContext context) {
    final bloc = context.read<ContactsBloc>();
    final currentState = bloc.state;
    final contacts = switch (currentState) {
      ContactsLoaded(:final contacts) => contacts,
      _ => <Contact>[],
    };
    showSearch(
      context: context,
      delegate: _ContactSearchDelegate(contacts: contacts),
    );
  }

  void _showMergeDialog(BuildContext context) {
    final sourceCtrl = TextEditingController();
    final targetCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Merge Contacts',
                style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Merge source into target. Source contact will be removed.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sourceCtrl,
              decoration: const InputDecoration(
                labelText: 'Source Contact ID (will be removed)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Contact ID (will be kept)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final source = sourceCtrl.text.trim();
                final target = targetCtrl.text.trim();
                if (source.isEmpty || target.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await getIt<Dio>().post<void>(
                    '/api/contacts/merge',
                    data: {
                      'source_id': source,
                      'target_id': target,
                    },
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contacts merged'),
                      ),
                    );
                    context
                        .read<ContactsBloc>()
                        .add(const ContactsLoadRequested());
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Merge failed: $e')),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Merge'),
            ),
          ],
        ),
      ),
    );
  }

  void _addContact(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider(
        create: (_) => ContactFormCubit(
          contactRepository: getIt<ContactRepository>(),
        ),
        child: const _ContactFormSheet(),
      ),
    ).then((created) {
      if ((created ?? false) && context.mounted) {
        context.read<ContactsBloc>().add(const ContactsLoadRequested());
      }
    });
  }
}

class _ContactFormSheet extends StatefulWidget {
  const _ContactFormSheet();

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  Future<List<Map<String, dynamic>>> _searchCompanies(String q) async {
    final companies =
        await getIt<CompanyRemoteDataSource>().getCompanies();
    return companies
        .where((c) => c.name.toLowerCase().contains(q.toLowerCase()))
        .map((c) => {'id': c.id, 'name': c.name})
        .toList();
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContactFormCubit, ContactFormState>(
      listener: (ctx, state) {
        if (state.submissionStatus == FormzSubmissionStatus.success) {
          Navigator.of(ctx).pop(true);
        }
      },
      builder: (ctx, state) {
        final cubit = ctx.read<ContactFormCubit>();
        final theme = Theme.of(ctx);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) =>
                SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Contact',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      errorText: state.firstName.displayError,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: cubit.firstNameChanged,
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      errorText: state.lastName.displayError,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: cubit.lastNameChanged,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: cubit.emailChanged,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: cubit.phoneChanged,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Job Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: cubit.jobTitleChanged,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // ── Company search ──
                  Text(
                    'Company',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SearchOrCreateField<Map<String, dynamic>>(
                    label: 'Search companies...',
                    onSearch: _searchCompanies,
                    itemLabel: (c) => c['name'] as String? ?? '',
                    createEntityLabel: 'company',
                    selectedItem: state.companyId != null
                        ? {
                            'id': state.companyId,
                            'name': state.companyName ?? state.companyId,
                          }
                        : null,
                    onSelected: (c) => cubit.companyChanged(
                      c['id'] as String?,
                      c['name'] as String?,
                    ),
                    onCleared: () => cubit.companyChanged(null, null),
                    onCreateTapped: _createCompany,
                  ),

                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state.submissionStatus ==
                              FormzSubmissionStatus.inProgress
                          ? null
                          : cubit.submitted,
                      icon: state.submissionStatus ==
                              FormzSubmissionStatus.inProgress
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Create Contact'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContactsList extends StatefulWidget {
  const _ContactsList({
    required this.state,
    this.statusFilter = const {},
    this.tagFilter = const {},
  });

  final ContactsLoaded state;
  final Set<String> statusFilter;
  final Set<String> tagFilter;

  @override
  State<_ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends State<_ContactsList> {
  final _scrollController = ScrollController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<ContactsBloc>().add(const ContactsLoadMoreRequested());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= maxScroll - 200;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var contacts = widget.state.contacts;
    final hasMore = widget.state.hasMore;

    // Apply search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      contacts = contacts.where((c) {
        final name = '${c.firstName} ${c.lastName}'.toLowerCase();
        return name.contains(q) ||
            c.email.toLowerCase().contains(q) ||
            (c.phone ?? '').contains(q) ||
            (c.jobTitle ?? '').toLowerCase().contains(q);
      }).toList();
    }
    // Apply sidebar filters
    if (widget.statusFilter.isNotEmpty) {
      contacts = contacts
          .where((c) => widget.statusFilter.contains(c.status))
          .toList();
    }
    if (widget.tagFilter.isNotEmpty) {
      contacts = contacts
          .where((c) => c.tags.any(widget.tagFilter.contains))
          .toList();
    }

    // Build active filter chips for display
    final activeFilters = <ActiveFilter>[
      for (final s in widget.statusFilter)
        ActiveFilter(label: 'Status: $s', onRemove: () {}),
      for (final t in widget.tagFilter)
        ActiveFilter(label: 'Tag: $t', onRemove: () {}),
    ];

    return Column(
      children: [
        // Persistent search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, email, phone...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _search = ''),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        // Active filter chips (from sidebar)
        ActiveFilterChips(filters: activeFilters),
        // List
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            itemCount: contacts.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= contacts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final contact = contacts[index];
              return ContactTile(
                contact: contact,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ContactDetailPage(contact: contact),
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

class _ContactSearchDelegate extends SearchDelegate<Contact?> {
  _ContactSearchDelegate({required this.contacts});

  final List<Contact> contacts;

  @override
  String get searchFieldLabel => 'Search contacts';

  @override
  List<Widget>? buildActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        tooltip: l10n.clearSearch,
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: l10n.back,
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lowerQuery = query.toLowerCase();
    final filtered = contacts.where((c) {
      final fullName = '${c.firstName} ${c.lastName}'.trim();
      return fullName.toLowerCase().contains(lowerQuery) ||
          c.email.toLowerCase().contains(lowerQuery) ||
          (c.phone?.contains(lowerQuery) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.searchNoResultsTitle,
        message: l10n.searchNoResultsMessage,
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final contact = filtered[index];
        return ContactTile(
          contact: contact,
          onTap: () => close(context, contact),
        );
      },
    );
  }
}

// ── Companies Tab ──────────────────────────────────────────────────────

class _CompaniesTab extends StatefulWidget {
  const _CompaniesTab();

  @override
  State<_CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends State<_CompaniesTab> {
  List<Company>? _companies;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final companies =
          await getIt<CompanyRemoteDataSource>().getCompanies();
      if (mounted) {
        setState(() { _companies = companies; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _companies = []; _loading = false; });
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    final industryCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: websiteCtrl,
                decoration: const InputDecoration(labelText: 'Website'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: industryCtrl,
                decoration:
                    const InputDecoration(labelText: 'Industry'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
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
                await getIt<CompanyRemoteDataSource>()
                    .createCompany(company);
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'companies_tab_fab',
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _companies == null || _companies!.isEmpty
              ? const EmptyState(
                  icon: Icons.business_outlined,
                  title: 'No companies',
                  message: 'Tap + to create your first company.',
                )
              : ListView.separated(
                  itemCount: _companies!.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final company = _companies![index];
                    return CompanyTile(
                      company: company,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CompanyDetailPage(company: company),
                        ),
                      ),
                      onUpdated: _load,
                    );
                  },
                ),
    );
  }
}
