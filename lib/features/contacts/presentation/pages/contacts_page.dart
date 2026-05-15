import 'package:cis_crm/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:cis_crm/features/contacts/presentation/widgets/contact_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: BlocBuilder<ContactsBloc, ContactsState>(
        builder: (context, state) {
          return switch (state) {
            ContactsInitial() => const Center(
                child: Text('Press load to fetch contacts.'),
              ),
            ContactsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ContactsLoaded(:final contacts) => ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) => ContactTile(
                  contact: contacts[index],
                ),
              ),
            ContactsError(:final failure) => Center(
                child: Text('Error: ${failure.message}'),
              ),
          };
        },
      ),
    );
  }
}
