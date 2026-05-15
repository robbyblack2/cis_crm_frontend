import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:json_annotation/json_annotation.dart';

part 'company_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
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

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);

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

  Map<String, dynamic> toJson() => _$CompanyModelToJson(this);
}
