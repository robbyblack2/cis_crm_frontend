import 'package:cis_crm/features/contacts/domain/entities/company.dart';

class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.name,
    required super.tags,
    required super.createdAt,
    required super.updatedAt,
    super.ownerId,
    super.domain,
    super.industry,
    super.phone,
    super.employeeCount,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return CompanyModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      name: data['name'] as String? ?? '',
      domain: data['domain'] as String?,
      industry: data['industry'] as String?,
      phone: data['phone'] as String?,
      employeeCount: data['employee_count'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory CompanyModel.fromEntity(Company company) => CompanyModel(
        id: company.id,
        ownerId: company.ownerId,
        name: company.name,
        domain: company.domain,
        industry: company.industry,
        phone: company.phone,
        employeeCount: company.employeeCount,
        tags: company.tags,
        createdAt: company.createdAt,
        updatedAt: company.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'data': {
          'name': name,
          'domain': domain,
          'industry': industry,
          'phone': phone,
          'employee_count': employeeCount,
        },
      };
}
