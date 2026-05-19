import 'package:cis_crm/features/contacts/domain/entities/contact.dart';

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
    super.version,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ContactModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      companyId: json['company_id'] as String?,
      firstName: data['first_name'] as String? ?? '',
      lastName: data['last_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      jobTitle: data['job_title'] as String?,
      source: data['source'] as String?,
      status: json['status'] as String? ?? 'active',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

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
        version: contact.version,
        createdAt: contact.createdAt,
        updatedAt: contact.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'company_id': companyId,
        'status': status,
        'tags': tags,
        'version': version,
        'data': {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'job_title': jobTitle,
          'source': source,
        },
      };
}
