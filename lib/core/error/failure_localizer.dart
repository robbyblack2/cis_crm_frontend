import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension FailureLocalizer on AppFailure {
  String localize(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      NetworkFailure() => l10n.failure_network,
      ServerFailure() => l10n.failure_server,
      UnauthorizedFailure() => l10n.failure_unauthorized,
      ValidationFailure() => l10n.failure_validation,
      CacheFailure() => l10n.failure_cache,
      UnknownFailure() => l10n.failure_unknown,
    };
  }
}
