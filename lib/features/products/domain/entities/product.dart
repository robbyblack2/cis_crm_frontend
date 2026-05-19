import 'package:cis_crm/features/products/domain/entities/product_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.isActive,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.defaultPrice,
    this.version = 1,
  });

  final String id;
  final String name;
  final ProductType type;
  final double? defaultPrice;
  final String currency;
  final bool isActive;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        defaultPrice,
        currency,
        isActive,
        tags,
        createdAt,
        updatedAt,
        version,
      ];
}
