import 'package:cis_crm/app/injection.dart';
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

class _ContactsView extends StatelessWidget {
  const _ContactsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.merge_type),
            tooltip: 'Merge contacts',
            onPressed: () => _showMergeDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.contactSearch,
            onPressed: () => _openSearch(context),
          ),
        ],
      ),
      body: BlocBuilder<ContactsBloc, ContactsState>(
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType || previous != current,
        builder: (context, state) {
          return switch (state) {
            ContactsInitial() || ContactsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
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
                : _ContactsList(state: state),
            ContactsError(:final failure) => PageError(
                title: l10n.failedToLoadContacts,
                message: failure.message,
                onRetry: () => context
                    .read<ContactsBloc>()
                    .add(const ContactsLoadRequested()),
              ),
          };
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

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge Contacts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Merge source into target. Source contact will be removed.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sourceCtrl,
              decoration: const InputDecoration(
                labelText: 'Source Contact ID (will be removed)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Contact ID (will be kept)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
  final _companySearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _companyResults = [];

  @override
  void dispose() {
    _companySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchCompanies(String q) async {
    if (q.length < 2) {
      setState(() => _companyResults = []);
      return;
    }
    try {
      final companies =
          await getIt<CompanyRemoteDataSource>().getCompanies();
      setState(() {
        _companyResults = companies
            .where((c) => c.name.toLowerCase().contains(q.toLowerCase()))
            .map((c) => {'id': c.id, 'name': c.name})
            .toList();
      });
    } catch (_) {
      setState(() => _companyResults = []);
    }
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
                  if (state.companyId != null)
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.business),
                        title: Text(state.companyName ?? state.companyId!),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              cubit.companyChanged(null, null),
                        ),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _companySearchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search companies...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: _searchCompanies,
                    ),
                    if (_companyResults.isNotEmpty)
                      Card(
                        child: Column(
                          children: _companyResults.take(5).map(
                            (c) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.business),
                              title: Text(c['name'] as String? ?? ''),
                              onTap: () {
                                cubit.companyChanged(
                                  c['id'] as String?,
                                  c['name'] as String?,
                                );
                                _companySearchCtrl.clear();
                                setState(() => _companyResults = []);
                              },
                            ),
                          ).toList(),
                        ),
                      ),
                  ],

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
  const _ContactsList({required this.state});

  final ContactsLoaded state;

  @override
  State<_ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends State<_ContactsList> {
  final _scrollController = ScrollController();

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
    final contacts = widget.state.contacts;
    final hasMore = widget.state.hasMore;

    return ListView.separated(
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
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primaryContainer,
                        child: Text(
                          company.name.isNotEmpty
                              ? company.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color:
                                theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(company.name),
                      subtitle: Text(
                        [
                          if (company.industry != null)
                            company.industry!,
                          if (company.domain != null) company.domain!,
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CompanyDetailPage(company: company),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
