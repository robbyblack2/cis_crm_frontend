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
    this.version = 1,
    this.ownerId,
    this.companyId,
    this.phone,
    this.jobTitle,
    this.source,
    this.googleContactId,
  });

  final String id;
  final String? googleContactId;
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
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? status,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? ownerId,
    String? companyId,
    String? phone,
    String? jobTitle,
    String? source,
    String? googleContactId,
  }) {
    return Contact(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      ownerId: ownerId ?? this.ownerId,
      companyId: companyId ?? this.companyId,
      phone: phone ?? this.phone,
      jobTitle: jobTitle ?? this.jobTitle,
      source: source ?? this.source,
      googleContactId: googleContactId ?? this.googleContactId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        googleContactId,
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
        version,
        createdAt,
        updatedAt,
      ];
}
