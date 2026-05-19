import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/models/contact_model.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';

class ContactRepositoryImpl implements ContactRepository {
  ContactRepositoryImpl({required this.remoteDataSource});

  final ContactRemoteDataSource remoteDataSource;

  @override
  Future<Result<PaginatedResponse<Contact>, AppFailure>> getContacts({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final response = await remoteDataSource.getContacts(
        page: page,
        perPage: perPage,
      );
      return Success(response);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Contact, AppFailure>> getContact(String id) async {
    try {
      final contact = await remoteDataSource.getContact(id);
      return Success(contact);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Contact, AppFailure>> createContact(Contact contact) async {
    try {
      final model = ContactModel.fromEntity(contact);
      final created = await remoteDataSource.createContact(model);
      return Success(created);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Contact, AppFailure>> updateContact(Contact contact) async {
    try {
      final model = ContactModel.fromEntity(contact);
      final updated = await remoteDataSource.updateContact(model);
      return Success(updated);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteContact(String id) async {
    try {
      await remoteDataSource.deleteContact(id);
      return const Success(null);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    } catch (e) {
      return Failure(UnknownFailure(e.toString()));
    }
  }

  AppFailure _mapExceptionToFailure(AppException exception) {
    return switch (exception) {
      NetworkException() => const NetworkFailure(),
      UnauthorizedException() => const UnauthorizedFailure(),
      ServerException(:final message, :final statusCode) =>
        ServerFailure(message, statusCode: statusCode),
      ValidationException(:final message, :final fieldErrors) =>
        ValidationFailure(message, fieldErrors: fieldErrors),
      CacheException(:final message) => CacheFailure(message),
    };
  }
}
