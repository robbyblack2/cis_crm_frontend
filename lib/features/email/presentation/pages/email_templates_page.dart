import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
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

class _EmailTemplatesView extends StatelessWidget {
  const _EmailTemplatesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.emailTemplatesTitle)),
      floatingActionButton: FloatingActionButton(
        tooltip: AppLocalizations.of(context)!.createTemplate,
        onPressed: () => _showCreateTemplateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<EmailBloc, EmailState>(
        builder: (context, state) {
          return switch (state) {
            EmailInitial() || EmailLoading() => const PageLoading(),
            EmailLoaded(templates: final templates?) when templates.isEmpty =>
              EmptyState(
                icon: Icons.description_outlined,
                title: AppLocalizations.of(context)!.emailTemplatesEmptyTitle,
                message: AppLocalizations.of(context)!.emailTemplatesEmptyMessage,
              ),
            EmailLoaded(templates: final templates?) => ListView.builder(
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  return EmailTemplateTile(template: templates[index]);
                },
              ),
            EmailError(:final failure) => PageError(
                title: AppLocalizations.of(context)!.failedToLoadTemplates,
                message: failure.message,
                onRetry: () {
                  context.read<EmailBloc>().add(const TemplatesLoadRequested());
                },
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createTemplate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.templateName),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(labelText: l10n.templateSubject),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                decoration: InputDecoration(labelText: l10n.templateBody),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final subject = subjectController.text.trim();
              final body = bodyController.text.trim();
              if (name.isEmpty || subject.isEmpty) return;
              context.read<EmailBloc>().add(
                    TemplateCreateRequested(
                      name: name,
                      subject: subject,
                      body: body,
                    ),
                  );
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }
}
