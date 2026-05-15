import 'package:cis_crm/features/reporting/domain/entities/report.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ReportModel extends Report {
  const ReportModel({
    required super.id,
    required super.name,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.description,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) =>
      _$ReportModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReportModelToJson(this);
}
