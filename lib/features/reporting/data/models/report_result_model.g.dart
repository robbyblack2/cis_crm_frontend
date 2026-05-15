// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportResultModel _$ReportResultModelFromJson(Map<String, dynamic> json) =>
    ReportResultModel(
      columns:
          (json['columns'] as List<dynamic>).map((e) => e as String).toList(),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$ReportResultModelToJson(ReportResultModel instance) =>
    <String, dynamic>{
      'columns': instance.columns,
      'rows': instance.rows,
    };
