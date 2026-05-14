import 'package:cis_crm/core/error/failures.dart';
import 'package:flutter/widgets.dart';

extension FailureLocalizer on AppFailure {
  String localize(BuildContext context) {
    return switch (this) {
      NetworkFailure() => 'No internet connection.',
      ServerFailure() => 'Server error. Please try again.',
      UnauthorizedFailure() => 'Please sign in again.',
      ValidationFailure() => 'Please check your input.',
      CacheFailure() => 'Local storage error.',
      UnknownFailure() => 'Something went wrong.',
    };
  }
}
