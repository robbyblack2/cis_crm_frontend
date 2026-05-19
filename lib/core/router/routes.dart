abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const forceUpgrade = '/force_upgrade';

  // ── Features ────────────────────────────────────────────────────
  static const contacts = '/contacts';
  static const pipelines = '/pipelines';
  static const calendar = '/calendar';
  static const tasks = '/tasks';
  static const products = '/products';
  static const reports = '/reports';

  static const search = '/search';
  static const profile = '/profile';
  static const settings = '/settings';
  static const integrations = '/integrations';
  static const automation = '/automation';
  static const emailTemplates = '/email-templates';
  static const emailCompose = '/email/compose';
  static const callLogs = '/call-logs';
  static const files = '/files';
  static const companies = '/companies';
  static const fieldDefinitions = '/field-definitions';
  static const tags = '/tags';
  static const savedViews = '/saved-views';
  static const emailSignature = '/email-signature';
  static const importExport = '/import-export';

  static const users = '/users';
  static const auditLog = '/audit-log';

  static const debugFlags = '/debug/flags';

  // ── Detail routes ───────────────────────────────────────────────
  static String contact(String id) => '/contacts/$id';
  static String company(String id) => '/companies/$id';
  static String pipeline(String id) => '/pipelines/$id';
  static String record(String id) => '/records/$id';
  static String product(String id) => '/products/$id';
  static String subscription(String id) => '/subscriptions/$id';
  static String report(String id) => '/reports/$id';
  static String task(String id) => '/tasks/$id';
}
