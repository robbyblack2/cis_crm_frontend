import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:flutter/material.dart';

class CompanyDetailPage extends StatelessWidget {
  const CompanyDetailPage({required this.company, super.key});

  final Company company;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = <String, dynamic>{
      'Name': company.name,
      if (company.domain != null) 'Website': company.domain,
      if (company.industry != null) 'Industry': company.industry,
      if (company.phone != null) 'Phone': company.phone,
      if (company.employeeCount != null)
        'Employees': company.employeeCount,
    };

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(company.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Contacts'),
              Tab(text: 'Records'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── Info tab ──
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in data.entries)
                        if (entry.value != null &&
                            entry.value.toString().isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    entry.key,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value.toString(),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      if (company.tags.isNotEmpty) ...[
                        const Divider(),
                        Wrap(
                          spacing: 8,
                          children: company.tags
                              .map(
                                (t) => Chip(
                                  label: Text(t),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Contacts tab ──
            _RelatedListTab(
              future: getIt<CompanyRemoteDataSource>()
                  .getCompanyContacts(company.id),
              emptyText: 'No contacts linked',
              itemBuilder: (item) {
                final d = item['data'] as Map<String, dynamic>? ?? {};
                final name =
                    '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'
                        .trim();
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(name.isNotEmpty ? name : 'Contact'),
                  subtitle:
                      Text(d['email'] as String? ?? ''),
                );
              },
            ),

            // ── Records tab ──
            _RelatedListTab(
              future: getIt<CompanyRemoteDataSource>()
                  .getCompanyRecords(company.id),
              emptyText: 'No records',
              itemBuilder: (item) {
                final d = item['data'] as Map<String, dynamic>? ?? {};
                return ListTile(
                  leading: const Icon(Icons.view_kanban_outlined),
                  title: Text(d['title'] as String? ?? 'Record'),
                  subtitle:
                      Text(item['source'] as String? ?? ''),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedListTab extends StatelessWidget {
  const _RelatedListTab({
    required this.future,
    required this.emptyText,
    required this.itemBuilder,
  });

  final Future<List<Map<String, dynamic>>> future;
  final String emptyText;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }
}
