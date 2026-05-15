// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LineItemModel _$LineItemModelFromJson(Map<String, dynamic> json) =>
    LineItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      parentType: json['parent_type'] as String,
      parentId: json['parent_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      serialNumber: json['serial_number'] as String?,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
    );

Map<String, dynamic> _$LineItemModelToJson(LineItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'parent_type': instance.parentType,
      'parent_id': instance.parentId,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'serial_number': instance.serialNumber,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
