import 'package:cis_crm/features/search/domain/entities/search_result.dart';

class SearchResultModel extends SearchResult {
  const SearchResultModel({
    required super.id,
    required super.entityType,
    required super.title,
    super.subtitle,
    super.matchedField,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    final entityType = json['entity_type'] as String? ?? '';
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rank = json['rank'];

    String title;
    switch (entityType) {
      case 'contact':
        final first = data['first_name'] as String? ?? '';
        final last = data['last_name'] as String? ?? '';
        title = '$first $last'.trim();
      case 'company':
        title = data['name'] as String? ?? '';
      default:
        title = data['name'] as String? ?? data['title'] as String? ?? '';
    }

    return SearchResultModel(
      id: json['id'] as String,
      entityType: entityType,
      title: title,
      subtitle: rank != null ? 'rank: $rank' : null,
      matchedField: json['matched_field'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'title': title,
        'subtitle': subtitle,
        'matched_field': matchedField,
      };
}
