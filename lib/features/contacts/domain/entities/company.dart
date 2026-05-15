import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId,
    this.domain,
    this.industry,
    this.phone,
    this.employeeCount,
  });

  final String id;
  final String? ownerId;
  final String name;
  final String? domain;
  final String? industry;
  final String? phone;
  final int? employeeCount;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        domain,
        industry,
        phone,
        employeeCount,
        tags,
        createdAt,
        updatedAt,
      ];
}
