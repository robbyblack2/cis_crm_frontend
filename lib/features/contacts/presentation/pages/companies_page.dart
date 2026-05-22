import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/filter_sidebar.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/companies_cubit.dart';
import 'package:cis_crm/features/contacts/presentation/pages/company_detail_page.dart';
import 'package:cis_crm/features/contacts/presentation/widgets/company_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CompaniesPage extends StatelessWidget {
  const CompaniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CompaniesCubit>()..loadCompanies(),
      child: const _CompaniesPageView(),
    );
  }
}

class _CompaniesPageView extends StatefulWidget {
  const _CompaniesPageView();

  @override
  State<_CompaniesPageView> createState() => _CompaniesPageViewState();
}

class _CompaniesPageViewState extends State<_CompaniesPageView> {
  bool _sidebarOpen = false;
  Set<String> _industryFilter = {};
  Set<String> _tagFilter = {};
  String _search = '';

  @override
  Widget build(BuildContext context) {
    var activeCount = 0;
    if (_industryFilter.isNotEmpty) activeCount++;
    if (_tagFilter.isNotEmpty) activeCount++;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies'),
        actions: [
          FilterToggleButton(
            activeCount: activeCount,
            isOpen: _sidebarOpen,
            onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
          ),
        ],
      ),
      body: BlocBuilder<CompaniesCubit, CompaniesState>(
        builder: (context, state) {
          final listContent = switch (state) {
            CompaniesInitial() ||
            CompaniesLoading() =>
              const Center(child: CircularProgressIndicator()) as Widget,
            CompaniesLoaded(:final companies) => companies.isEmpty
                ? EmptyState(
                    icon: Icons.business_outlined,
                    title: 'No companies',
                    message: 'Tap + to create your first company.',
                    action: FilledButton.icon(
                      onPressed: () => _showCreateSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Company'),
                    ),
                  )
                : _buildList(context, companies),
            CompaniesError(:final failure) => PageError(
                title: 'Failed to load companies',
                message: failure.message,
                onRetry: () =>
                    context.read<CompaniesCubit>().loadCompanies(),
              ),
          };

          // Build sidebar sections
          final allIndustries = <String>[];
          final allTags = <String>[];
          int totalCount = 0;
          if (state is CompaniesLoaded) {
            allIndustries.addAll(
              state.companies
                  .map((c) => c.industry)
                  .whereType<String>()
                  .where((i) => i.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort(),
            );
            allTags.addAll(
              state.companies
                  .expand((c) => c.tags)
                  .toSet()
                  .toList()
                ..sort(),
            );
            totalCount = state.companies.length;
          }

          return Row(
            children: [
              Expanded(child: listContent),
              if (_sidebarOpen)
                FilterSidebar(
                  totalCount: totalCount,
                  onClearAll: () => setState(() {
                    _industryFilter = {};
                    _tagFilter = {};
                  }),
                  sections: [
                    FilterSection.checkboxGroup(
                      title: 'Industry',
                      options: allIndustries
                          .map((i) => FilterOption(value: i, label: i))
                          .toList(),
                      selected: _industryFilter,
                      onChanged: (v) =>
                          setState(() => _industryFilter = v),
                    ),
                    FilterSection.checkboxGroup(
                      title: 'Tags',
                      options: allTags
                          .map((t) => FilterOption(value: t, label: t))
                          .toList(),
                      selected: _tagFilter,
                      onChanged: (v) =>
                          setState(() => _tagFilter = v),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'companies_fab',
        tooltip: 'Add company',
        onPressed: () => _showCreateSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Company> allCompanies) {
    var companies = allCompanies;

    // Apply search (name, domain, industry, phone, tags)
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      companies = companies.where((c) {
        return c.name.toLowerCase().contains(q) ||
            (c.domain ?? '').toLowerCase().contains(q) ||
            (c.industry ?? '').toLowerCase().contains(q) ||
            (c.phone ?? '').contains(q) ||
            c.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }
    // Apply sidebar filters
    if (_industryFilter.isNotEmpty) {
      companies = companies
          .where((c) => _industryFilter.contains(c.industry))
          .toList();
    }
    if (_tagFilter.isNotEmpty) {
      companies = companies
          .where((c) => c.tags.any(_tagFilter.contains))
          .toList();
    }

    final activeFilters = <ActiveFilter>[
      for (final i in _industryFilter)
        ActiveFilter(
          label: 'Industry: $i',
          onRemove: () => setState(() {
            _industryFilter = Set.from(_industryFilter)..remove(i);
          }),
        ),
      for (final t in _tagFilter)
        ActiveFilter(
          label: 'Tag: $t',
          onRemove: () => setState(() {
            _tagFilter = Set.from(_tagFilter)..remove(t);
          }),
        ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, domain, industry, tags...',
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
        ActiveFilterChips(filters: activeFilters),
        Expanded(
          child: ListView.separated(
            itemCount: companies.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final company = companies[index];
              return CompanyTile(
                company: company,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompanyDetailPage(company: company),
                  ),
                ),
                onUpdated: () =>
                    context.read<CompaniesCubit>().loadCompanies(),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateSheet(BuildContext context) {
    final cubit = context.read<CompaniesCubit>();
    final nameCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    final industryCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
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
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Company',
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
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: websiteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: industryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Industry',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma-separated)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        final tags = tagsCtrl.text
                            .split(',')
                            .map((t) => t.trim())
                            .where((t) => t.isNotEmpty)
                            .toList();
                        cubit.createCompany(
                          Company(
                            id: '',
                            name: name,
                            domain: websiteCtrl.text.trim().isNotEmpty
                                ? websiteCtrl.text.trim()
                                : null,
                            industry: industryCtrl.text.trim().isNotEmpty
                                ? industryCtrl.text.trim()
                                : null,
                            phone: phoneCtrl.text.trim().isNotEmpty
                                ? phoneCtrl.text.trim()
                                : null,
                            tags: tags,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(ctx)!.create),
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
