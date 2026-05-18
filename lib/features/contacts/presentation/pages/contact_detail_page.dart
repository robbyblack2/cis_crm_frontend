import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/responsive/breakpoints.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contact_form_cubit.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:cis_crm/features/files/domain/repositories/file_repository.dart';
import 'package:cis_crm/features/files/presentation/widgets/file_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

String _fullName(Contact c) => '${c.firstName} ${c.lastName}'.trim();

String _initials(Contact c) {
  final first = c.firstName.isNotEmpty ? c.firstName[0] : '';
  final last = c.lastName.isNotEmpty ? c.lastName[0] : '';
  return '$first$last'.toUpperCase();
}

class ContactDetailPage extends StatelessWidget {
  const ContactDetailPage({
    required this.contact,
    super.key,
  });

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fullName(contact)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppLocalizations.of(context)!.editContact,
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            tooltip: AppLocalizations.of(context)!.deleteContact,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final windowSize = windowSizeFor(constraints.maxWidth);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: switch (windowSize) {
              WindowSize.compact => _CompactLayout(contact: contact),
              WindowSize.medium ||
              WindowSize.expanded =>
                _WideLayout(contact: contact),
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (_) => ContactFormCubit(
          contactRepository: getIt<ContactRepository>(),
          existingContact: contact,
        ),
        child: BlocConsumer<ContactFormCubit, ContactFormState>(
          listener: (ctx, state) {
            if (state.submissionStatus == FormzSubmissionStatus.success) {
              Navigator.of(ctx).pop(true);
            }
          },
          builder: (ctx, state) {
            final cubit = ctx.read<ContactFormCubit>();
            final isSubmitting =
                state.submissionStatus == FormzSubmissionStatus.inProgress;

            return AlertDialog(
              title: Text(AppLocalizations.of(ctx)!.editContact),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: TextEditingController.fromValue(
                        TextEditingValue(
                          text: state.firstName.value,
                          selection: TextSelection.collapsed(
                            offset: state.firstName.value.length,
                          ),
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(ctx)!.contactFirstName,
                        errorText: state.firstName.displayError,
                      ),
                      onChanged: cubit.firstNameChanged,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController.fromValue(
                        TextEditingValue(
                          text: state.lastName.value,
                          selection: TextSelection.collapsed(
                            offset: state.lastName.value.length,
                          ),
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(ctx)!.contactLastName,
                        errorText: state.lastName.displayError,
                      ),
                      onChanged: cubit.lastNameChanged,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.email,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(ctx)!.contactEmail,
                      ),
                      onChanged: cubit.emailChanged,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.phone,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(ctx)!.contactPhone,
                      ),
                      onChanged: cubit.phoneChanged,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.jobTitle,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(ctx)!.contactJobTitle,
                      ),
                      onChanged: cubit.jobTitleChanged,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.source,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(ctx)!.contactSource,
                      ),
                      onChanged: cubit.sourceChanged,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: Text(AppLocalizations.of(ctx)!.cancel),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : cubit.submitted,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(ctx)!.save),
                ),
              ],
            );
          },
        ),
      ),
    ).then((saved) {
      if ((saved ?? false) && context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.contactDeleteTitle),
        content: Text(
          l10n.contactDeleteConfirmName(_fullName(contact)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final result = await getIt<ContactRepository>()
                  .deleteContact(contact.id);
              if (!context.mounted) return;
              switch (result) {
                case Success():
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.contactDeleted)),
                  );
                  Navigator.of(context).pop();
                case Failure(:final error):
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.contactDeleteFailed(error.message)),
                    ),
                  );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _ContactHeader extends StatelessWidget {
  const _ContactHeader({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                _initials(contact),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _fullName(contact),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (contact.jobTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                contact.jobTitle!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            _StatusChip(status: contact.status),
          ],
        ),
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: l10n.contactEmail,
              value: contact.email,
            ),
            if (contact.phone != null)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: l10n.contactPhone,
                value: contact.phone!,
              ),
            if (contact.source != null)
              _InfoRow(
                icon: Icons.source_outlined,
                label: l10n.contactSource,
                value: contact.source!,
              ),
            if (contact.companyId != null)
              _InfoRow(
                icon: Icons.business_outlined,
                label: l10n.contactCompany,
                value: contact.companyId!,
              ),
          ],
        ),
      ),
    );
  }
}

class _TagsCard extends StatelessWidget {
  const _TagsCard({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.contactTags, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(label, style: theme.textTheme.labelMedium),
      subtitle: Text(value, style: theme.textTheme.bodyLarge),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = switch (status) {
      'active' => (l10n.contactStatusActive, Colors.green),
      'inactive' => (l10n.contactStatusInactive, Colors.grey),
      'lead' => (l10n.contactStatusLead, Colors.orange),
      'prospect' => (l10n.contactStatusProspect, Colors.blue),
      'customer' => (l10n.contactStatusCustomer, Colors.purple),
      _ => (status, Colors.grey),
    };

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color.shade700),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _FilesSection extends StatelessWidget {
  const _FilesSection({required this.contactId});

  final String contactId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Files', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'File upload requires file_picker package',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<Result<List<FileAttachment>, AppFailure>>(
              future: getIt<FileRepository>().getFilesByParent(
                parentType: 'contact',
                parentId: contactId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Failed to load files.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                final result = snapshot.data;
                if (result == null) {
                  return const SizedBox.shrink();
                }

                return switch (result) {
                  Success(:final data) when data.isEmpty => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'No files attached to this contact.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Success(:final data) => Column(
                      children: data
                          .map(
                            (file) => FileTile(
                              file: file,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Download: ${file.filename}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  Failure(:final error) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Error: ${error.message}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContactHeader(contact: contact),
        const SizedBox(height: 16),
        _ContactInfoCard(contact: contact),
        if (contact.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _TagsCard(tags: contact.tags),
        ],
        const SizedBox(height: 16),
        _FilesSection(contactId: contact.id),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ContactHeader(contact: contact),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContactInfoCard(contact: contact),
              if (contact.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TagsCard(tags: contact.tags),
              ],
              const SizedBox(height: 16),
              _FilesSection(contactId: contact.id),
            ],
          ),
        ),
      ],
    );
  }
}
