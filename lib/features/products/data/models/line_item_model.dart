import 'package:cis_crm/features/products/domain/entities/line_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'line_item_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class LineItemModel extends LineItem {
  const LineItemModel({
    required super.id,
    required super.productId,
    required super.parentType,
    required super.parentId,
    required super.quantity,
    required super.unitPrice,
    required super.createdAt,
    super.serialNumber,
    super.startDate,
    super.endDate,
  });

  factory LineItemModel.fromJson(Map<String, dynamic> json) =>
      _$LineItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$LineItemModelToJson(this);
}
