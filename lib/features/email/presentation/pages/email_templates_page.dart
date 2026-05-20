import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:cis_crm/features/email/presentation/bloc/email_bloc.dart';
import 'package:cis_crm/features/email/presentation/widgets/email_template_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailTemplatesPage extends StatelessWidget {
  const EmailTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmailBloc>()..add(const TemplatesLoadRequested()),
      child: const _EmailTemplatesView(),
    );
  }
}

class _EmailTemplatesView extends StatefulWidget {
  const _EmailTemplatesView();

  @override
  State<_EmailTemplatesView> createState() => _EmailTemplatesViewState();
}

class _EmailTemplatesViewState extends State<_EmailTemplatesView> {
  String _search = '';

  static const _variables = [
    ('{{contact_name}}', 'Contact full name'),
    ('{{contact_first_name}}', 'Contact first name'),
    ('{{contact_email}}', 'Contact email'),
    ('{{company_name}}', 'Company name'),
    ('{{record_title}}', 'Record title'),
    ('{{user_name}}', 'Your name'),
    ('{{user_email}}', 'Your email'),
    ('{{date}}', 'Current date'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emailTemplatesTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'email_templates_fab',
        tooltip: l10n.createTemplate,
        onPressed: () => _showTemplateForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
      body: BlocBuilder<EmailBloc, EmailState>(
        builder: (context, state) {
          return switch (state) {
            EmailInitial() || EmailLoading() => const PageLoading(),
            EmailLoaded(templates: final templates?) when templates.isEmpty =>
              EmptyState(
                icon: Icons.description_outlined,
                title: l10n.emailTemplatesEmptyTitle,
                message: l10n.emailTemplatesEmptyMessage,
              ),
            EmailLoaded(templates: final templates?) =>
              _buildList(context, templates),
            EmailError(:final failure) => PageError(
                title: l10n.failedToLoadTemplates,
                message: failure.message,
                onRetry: () {
                  context
                      .read<EmailBloc>()
                      .add(const TemplatesLoadRequested());
                },
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<EmailTemplate> templates) {
    final filtered = _search.isEmpty
        ? templates
        : templates.where((t) {
            final name = (t.name as String? ?? '').toLowerCase();
            final subject = (t.subject as String? ?? '').toLowerCase();
            final q = _search.toLowerCase();
            return name.contains(q) || subject.contains(q);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return EmailTemplateTile(template: filtered[index]);
            },
          ),
        ),
      ],
    );
  }

  void _showTemplateForm(
    BuildContext context, {
    String? existingName,
    String? existingSubject,
    String? existingBody,
    bool isEditing = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: existingName ?? '');
    final subjectCtrl = TextEditingController(text: existingSubject ?? '');
    final bodyCtrl = TextEditingController(text: existingBody ?? '');

    // Track which field to insert variable into
    TextEditingController? activeField;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                  isEditing ? 'Edit Template' : 'New Template',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.templateName,
                    border: const OutlineInputBorder(),
                    hintText: 'e.g., Follow-up after demo',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.templateSubject,
                    border: const OutlineInputBorder(),
                    hintText: 'Hi {{contact_name}}, re: {{record_title}}',
                  ),
                  onTap: () =>
                      setSheetState(() => activeField = subjectCtrl),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.templateBody,
                    border: const OutlineInputBorder(),
                    hintText: 'Write your template...',
                  ),
                  maxLines: 8,
                  minLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onTap: () =>
                      setSheetState(() => activeField = bodyCtrl),
                ),
                const SizedBox(height: 12),

                // Variable picker
                Text(
                  'Insert variable',
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _variables.map((v) {
                    return ActionChip(
                      label: Text(v.$1,
                          style: Theme.of(ctx)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontFamily: 'monospace')),
                      tooltip: v.$2,
                      onPressed: () {
                        final target = activeField ?? bodyCtrl;
                        final text = target.text;
                        final sel = target.selection;
                        final pos = sel.isValid ? sel.baseOffset : text.length;
                        final newText = text.substring(0, pos) +
                            v.$1 +
                            text.substring(pos);
                        target.text = newText;
                        target.selection = TextSelection.collapsed(
                          offset: pos + v.$1.length,
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final subject = subjectCtrl.text.trim();
                    final body = bodyCtrl.text.trim();
                    if (name.isEmpty || subject.isEmpty) return;
                    context.read<EmailBloc>().add(
                          TemplateCreateRequested(
                            name: name,
                            subject: subject,
                            body: body,
                          ),
                        );
                    Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? 'Save' : l10n.create),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
