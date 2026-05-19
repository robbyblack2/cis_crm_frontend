import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/models/company_model.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/domain/repositories/company_repository.dart';
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
                decoration:
                    const InputDecoration(labelText: 'Website'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: industryCtrl,
                decoration:
                    const InputDecoration(labelText: 'Industry'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
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
