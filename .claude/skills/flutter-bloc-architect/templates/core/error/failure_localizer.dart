import 'package:flutter/widgets.dart';

import 'failures.dart';

// Replace with the generated AppLocalizations import once `flutter gen-l10n`
// has run for the project.
// import '../../l10n/generated/app_localizations.dart';

/// Maps an [AppFailure] subtype to its localized user-facing string.
///
/// Widgets call `failure.localize(context)` instead of switching on
/// failure types themselves. Blocs never localize — they emit failure
/// types and the widget layer translates.
///
/// The skill ships canonical ARB keys (`failure_network`, `failure_server`,
/// `failure_unauthorized`, `failure_validation`, `failure_cache`,
/// `failure_unknown`). Projects override copy by editing their ARB files;
/// the keys are stable.
extension FailureLocalizer on AppFailure {
  String localize(BuildContext context) {
    // final l = AppLocalizations.of(context)!;
    // return switch (this) {
    //   NetworkFailure() => l.failure_network,
    //   ServerFailure() => l.failure_server,
    //   UnauthorizedFailure() => l.failure_unauthorized,
    //   ValidationFailure() => l.failure_validation,
    //   CacheFailure() => l.failure_cache,
    //   UnknownFailure() => l.failure_unknown,
    // };
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
