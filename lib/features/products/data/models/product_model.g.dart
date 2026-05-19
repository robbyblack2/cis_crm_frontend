// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$ProductTypeEnumMap, json['type']),
      currency: json['currency'] as String,
      isActive: json['is_active'] as bool,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      defaultPrice: (json['default_price'] as num?)?.toDouble(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ProductTypeEnumMap[instance.type]!,
      'default_price': instance.defaultPrice,
      'currency': instance.currency,
      'is_active': instance.isActive,
      'tags': instance.tags,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'version': instance.version,
    };

const _$ProductTypeEnumMap = {
  ProductType.hardware: 'hardware',
  ProductType.subscription: 'subscription',
  ProductType.service: 'service',
};
