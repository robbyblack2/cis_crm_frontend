import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class LineItem extends Equatable {
  const LineItem({
    required this.id,
    required this.productId,
    required this.parentType,
    required this.parentId,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
    this.serialNumber,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String productId;
  final String parentType;
  final String parentId;
  final int quantity;
  final double unitPrice;
  final String? serialNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        productId,
        parentType,
        parentId,
        quantity,
        unitPrice,
        serialNumber,
        startDate,
        endDate,
        createdAt,
      ];
}
