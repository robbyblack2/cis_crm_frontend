import 'package:cis_crm/features/products/domain/entities/product.dart';
import 'package:cis_crm/features/products/domain/entities/product_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.type,
    required super.currency,
    required super.isActive,
    required super.tags,
    required super.createdAt,
    required super.updatedAt,
    super.defaultPrice,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
