import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_result_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SearchResultModel extends SearchResult {
  const SearchResultModel({
    required super.id,
    required super.entityType,
    required super.title,
    super.subtitle,
    super.matchedField,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) =>
      _$SearchResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResultModelToJson(this);
}
