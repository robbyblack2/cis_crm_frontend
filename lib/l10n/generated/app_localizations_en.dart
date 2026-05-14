// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CIS CRM';

  @override
  String get loading => 'Loading';

  @override
  String get retry => 'Retry';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get failure_network =>
      'No internet connection. Check your network and try again.';

  @override
  String get failure_server =>
      'Something went wrong on our end. Please try again in a moment.';

  @override
  String get failure_unauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get failure_validation =>
      'Please check the highlighted fields and try again.';

  @override
  String get failure_cache =>
      'We couldn\'t read local data. Try restarting the app.';

  @override
  String get failure_unknown => 'Something went wrong. Please try again.';
}
