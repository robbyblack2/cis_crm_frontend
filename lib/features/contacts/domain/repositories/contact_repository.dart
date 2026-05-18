import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';

abstract class ContactRepository {
  Future<Result<PaginatedResponse<Contact>, AppFailure>> getContacts({
    int page = 1,
    int perPage = 25,
  });
  Future<Result<Contact, AppFailure>> getContact(String id);
  Future<Result<Contact, AppFailure>> createContact(Contact contact);
  Future<Result<Contact, AppFailure>> updateContact(Contact contact);
  Future<Result<void, AppFailure>> deleteContact(String id);
}
