// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResultModel _$SearchResultModelFromJson(Map<String, dynamic> json) =>
    SearchResultModel(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      matchedField: json['matched_field'] as String?,
    );

Map<String, dynamic> _$SearchResultModelToJson(SearchResultModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entity_type': instance.entityType,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'matched_field': instance.matchedField,
    };
