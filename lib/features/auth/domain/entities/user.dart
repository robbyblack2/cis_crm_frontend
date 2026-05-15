import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.status,
  });

  static const empty = User(
    id: '',
    email: '',
    displayName: '',
    status: UserStatus.disabled,
  );

  final String id;
  final String email;
  final String displayName;
  final UserStatus status;

  bool get isEmpty => this == empty;
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props => [id, email, displayName, status];
}

enum UserStatus { active, disabled }
