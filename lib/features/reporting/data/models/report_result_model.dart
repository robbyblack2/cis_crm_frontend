import 'package:cis_crm/features/reporting/domain/entities/report_result.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_result_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ReportResultModel extends ReportResult {
  const ReportResultModel({
    required super.columns,
    required super.rows,
  });

  factory ReportResultModel.fromJson(Map<String, dynamic> json) =>
      _$ReportResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReportResultModelToJson(this);
}
