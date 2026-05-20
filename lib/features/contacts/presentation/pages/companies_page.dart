import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/models/company_model.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/presentation/pages/company_detail_page.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  List<Company>? _companies;
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final companies =
          await getIt<CompanyRemoteDataSource>().getCompanies();
      if (mounted) {
        setState(() {
          _companies = companies;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _companies = []; _loading = false; });
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    final industryCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create Company',
                  style: Theme.of(ctx).textTheme.headlineSmall),
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
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  final tags = tagsCtrl.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
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
                      phone: phoneCtrl.text.trim().isNotEmpty
                          ? phoneCtrl.text.trim()
                          : null,
                      tags: tags,
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
                child: Text(AppLocalizations.of(ctx)!.create),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Companies')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'companies_fab',
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search companies...',
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
                    Expanded(
                      child: Builder(builder: (context) {
                        var companies = _companies!;
                        if (_search.isNotEmpty) {
                          final q = _search.toLowerCase();
                          companies = companies
                              .where((c) =>
                                  c.name.toLowerCase().contains(q) ||
                                  (c.domain ?? '').toLowerCase().contains(q) ||
                                  (c.industry ?? '').toLowerCase().contains(q))
                              .toList();
                        }
                        return ListView.separated(
                  itemCount: companies.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    return InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CompanyDetailPage(company: company),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                company.name.isNotEmpty
                                    ? company.name[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name
                            Expanded(
                              flex: 3,
                              child: Text(
                                company.name,
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Domain
                            Expanded(
                              flex: 2,
                              child: Text(
                                company.domain ?? '',
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Industry
                            Expanded(
                              flex: 2,
                              child: Text(
                                company.industry ?? '',
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Phone
                            if (company.phone != null &&
                                company.phone!.isNotEmpty)
                              Expanded(
                                flex: 2,
                                child: Text(
                                  company.phone!,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            else
                              const Expanded(
                                flex: 2,
                                child: SizedBox.shrink(),
                              ),
                            // Tags
                            if (company.tags.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ...company.tags.take(2).map((tag) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(right: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
                      }),
                    ),
                  ],
                ),
    );
  }
}
