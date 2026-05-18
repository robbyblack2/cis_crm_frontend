import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/email/presentation/bloc/email_bloc.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailComposePage extends StatelessWidget {
  const EmailComposePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmailBloc>(),
      child: const _EmailComposeView(),
    );
  }
}

class _EmailComposeView extends StatefulWidget {
  const _EmailComposeView();

  @override
  State<_EmailComposeView> createState() => _EmailComposeViewState();
}

class _EmailComposeViewState extends State<_EmailComposeView> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmailBloc, EmailState>(
      listener: (context, state) {
        switch (state) {
          case EmailLoaded(sentMessage: final msg) when msg != null:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.emailSentSuccess)),
            );
            Navigator.of(context).pop();
          case EmailLoaded(savedDraft: final draft) when draft != null:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.draftSaved)),
            );
          case EmailError(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
          case _:
            break;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.emailComposeTitle),
          actions: [
            BlocBuilder<EmailBloc, EmailState>(
              builder: (context, state) {
                final isSending = state is EmailLoading;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.saveDraftTooltip,
                      icon: const Icon(Icons.save_outlined),
                      onPressed: isSending ? null : _saveDraft,
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.sendEmailTooltip,
                      icon: const Icon(Icons.send),
                      onPressed: isSending ? null : _sendEmail,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _toController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.emailTo,
                  hintText: AppLocalizations.of(context)!.emailToHint,
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.emailRecipientRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.emailSubject,
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.emailSubjectRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.emailBody,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 12,
                minLines: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendEmail() {
    if (!_formKey.currentState!.validate()) return;

    context.read<EmailBloc>().add(
          EmailSendRequested(
            recipientEmails: _toController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
            subject: _subjectController.text,
            body: _bodyController.text,
          ),
        );
  }

  void _saveDraft() {
    context.read<EmailBloc>().add(
          DraftSaveRequested(
            recipientEmails: _toController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
            subject: _subjectController.text,
            body: _bodyController.text,
          ),
        );
  }
}
