import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class Contact extends Equatable {
  const Contact({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.status,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId,
    this.companyId,
    this.phone,
    this.jobTitle,
    this.source,
  });

  final String id;
  final String? ownerId;
  final String? companyId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? jobTitle;
  final String? source;
  final String status;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        ownerId,
        companyId,
        firstName,
        lastName,
        email,
        phone,
        jobTitle,
        source,
        status,
        tags,
        createdAt,
        updatedAt,
      ];
}
