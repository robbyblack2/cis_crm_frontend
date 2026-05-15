import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:json_annotation/json_annotation.dart';

part 'contact_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ContactModel extends Contact {
  const ContactModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.status,
    required super.tags,
    required super.createdAt,
    required super.updatedAt,
    super.ownerId,
    super.companyId,
    super.phone,
    super.jobTitle,
    super.source,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) =>
      _$ContactModelFromJson(json);

  factory ContactModel.fromEntity(Contact contact) => ContactModel(
        id: contact.id,
        ownerId: contact.ownerId,
        companyId: contact.companyId,
        firstName: contact.firstName,
        lastName: contact.lastName,
        email: contact.email,
        phone: contact.phone,
        jobTitle: contact.jobTitle,
        source: contact.source,
        status: contact.status,
        tags: contact.tags,
        createdAt: contact.createdAt,
        updatedAt: contact.updatedAt,
      );

  Map<String, dynamic> toJson() => _$ContactModelToJson(this);
}
