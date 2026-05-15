import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/email/presentation/bloc/email_bloc.dart';
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
              const SnackBar(content: Text('Email sent successfully')),
            );
            Navigator.of(context).pop();
          case EmailLoaded(savedDraft: final draft) when draft != null:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Draft saved')),
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
          title: const Text('Compose Email'),
          actions: [
            BlocBuilder<EmailBloc, EmailState>(
              builder: (context, state) {
                final isSending = state is EmailLoading;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Save draft',
                      icon: const Icon(Icons.save_outlined),
                      onPressed: isSending ? null : _saveDraft,
                    ),
                    IconButton(
                      tooltip: 'Send email',
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
                decoration: const InputDecoration(
                  labelText: 'To',
                  hintText: 'recipient@example.com',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Recipient is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
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
