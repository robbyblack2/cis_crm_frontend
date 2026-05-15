import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';

abstract class ContactRepository {
  Future<Result<List<Contact>, AppFailure>> getContacts();
  Future<Result<Contact, AppFailure>> getContact(String id);
  Future<Result<Contact, AppFailure>> createContact(Contact contact);
  Future<Result<Contact, AppFailure>> updateContact(Contact contact);
  Future<Result<void, AppFailure>> deleteContact(String id);
}
