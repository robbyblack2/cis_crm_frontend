import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contact_form_cubit.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contacts_bloc.dart';
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
      child: const _ContactsView(),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (_) => ContactFormCubit(
          contactRepository: getIt<ContactRepository>(),
        ),
        child: BlocConsumer<ContactFormCubit, ContactFormState>(
          listener: (ctx, state) {
            if (state.submissionStatus == FormzSubmissionStatus.success) {
              Navigator.of(ctx).pop(true);
            }
          },
          builder: (ctx, state) {
            final cubit = ctx.read<ContactFormCubit>();
            return AlertDialog(
              title: Text(l10n.addContact),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.contactFirstName,
                        errorText: state.firstName.displayError,
                      ),
                      onChanged: cubit.firstNameChanged,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.contactLastName,
                        errorText: state.lastName.displayError,
                      ),
                      onChanged: cubit.lastNameChanged,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(labelText: l10n.contactEmail),
                      onChanged: cubit.emailChanged,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(labelText: l10n.contactPhone),
                      onChanged: cubit.phoneChanged,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.contactJobTitle,
                      ),
                      onChanged: cubit.jobTitleChanged,
                      textCapitalization: TextCapitalization.words,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 8),
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
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: state.submissionStatus ==
                          FormzSubmissionStatus.inProgress
                      ? null
                      : cubit.submitted,
                  child: state.submissionStatus ==
                          FormzSubmissionStatus.inProgress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.create),
                ),
              ],
            );
          },
        ),
      ),
    ).then((created) {
      if ((created ?? false) && context.mounted) {
        context.read<ContactsBloc>().add(const ContactsLoadRequested());
      }
    });
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
