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

  @override
  String get navPipeline => 'Pipeline';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navProducts => 'Products';

  @override
  String get navReports => 'Reports';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get search => 'Search';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get create => 'Create';

  @override
  String get add => 'Add';

  @override
  String get noResults => 'No results found';

  @override
  String get confirmDelete => 'Confirm delete';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this item? This action cannot be undone.';

  @override
  String get loginTitle => 'Sign in to CIS CRM';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginEmailInvalid => 'Please enter a valid email address.';

  @override
  String get loginPasswordTooShort => 'Password must be at least 8 characters.';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsEmpty => 'No contacts yet';

  @override
  String get contactsEmptyMessage => 'Add your first contact to get started.';

  @override
  String get contactSearch => 'Search contacts';

  @override
  String get contactFirstName => 'First name';

  @override
  String get contactLastName => 'Last name';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactPhone => 'Phone';

  @override
  String get contactJobTitle => 'Job title';

  @override
  String get contactSource => 'Source';

  @override
  String get contactStatus => 'Status';

  @override
  String get contactTags => 'Tags';

  @override
  String get contactDeleteConfirm =>
      'Are you sure you want to delete this contact?';

  @override
  String get pipelineTitle => 'Pipeline';

  @override
  String get pipelineEmpty => 'No deals in your pipeline';

  @override
  String get recordCreate => 'Create record';

  @override
  String get recordTitle => 'Title';

  @override
  String get recordMove => 'Move';

  @override
  String get recordStageHistory => 'Stage history';

  @override
  String get kanbanEmpty => 'No records in this stage';

  @override
  String get stageWon => 'Won';

  @override
  String get stageLost => 'Lost';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksEmpty => 'No tasks yet';

  @override
  String get tasksEmptyMessage => 'Create a task to start tracking your work.';

  @override
  String get taskTodo => 'To do';

  @override
  String get taskInProgress => 'In progress';

  @override
  String get taskDone => 'Done';

  @override
  String get taskPriorityLow => 'Low';

  @override
  String get taskPriorityMedium => 'Medium';

  @override
  String get taskPriorityHigh => 'High';

  @override
  String get taskTitle => 'Title';

  @override
  String get taskDescription => 'Description';

  @override
  String get taskDueDate => 'Due date';

  @override
  String get taskAssignee => 'Assignee';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarEmpty => 'No events scheduled';

  @override
  String get calendarToday => 'Today';

  @override
  String get viewDay => 'Day';

  @override
  String get viewWeek => 'Week';

  @override
  String get viewMonth => 'Month';

  @override
  String get eventTitle => 'Event title';

  @override
  String get eventLocation => 'Location';

  @override
  String get eventMeetingLink => 'Meeting link';

  @override
  String get productsTitle => 'Products';

  @override
  String get catalogTab => 'Catalog';

  @override
  String get subscriptionsTab => 'Subscriptions';

  @override
  String get productName => 'Product name';

  @override
  String get productType => 'Type';

  @override
  String get productPrice => 'Price';

  @override
  String get productActive => 'Active';

  @override
  String get productInactive => 'Inactive';

  @override
  String get subscriptionSystemId => 'System ID';

  @override
  String get subscriptionStatus => 'Subscription status';

  @override
  String get statusTrialing => 'Trialing';

  @override
  String get statusActive => 'Active';

  @override
  String get statusPastDue => 'Past due';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusExpired => 'Expired';

  @override
  String get emailCompose => 'Compose';

  @override
  String get emailSend => 'Send';

  @override
  String get emailSaveDraft => 'Save draft';

  @override
  String get emailTo => 'To';

  @override
  String get emailSubject => 'Subject';

  @override
  String get emailBody => 'Body';

  @override
  String get emailTemplates => 'Templates';

  @override
  String get emailTemplatesEmpty => 'No templates available';

  @override
  String get filesTitle => 'Files';

  @override
  String get filesEmpty => 'No files uploaded';

  @override
  String get uploadFile => 'Upload file';

  @override
  String get deleteFile => 'Delete file';

  @override
  String get automationTitle => 'Automation';

  @override
  String get automationEmpty => 'No automation rules';

  @override
  String get automationRuleActive => 'Active';

  @override
  String get automationRuleInactive => 'Inactive';

  @override
  String get executionLog => 'Execution log';

  @override
  String get executionSuccess => 'Success';

  @override
  String get executionFailed => 'Failed';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsEmpty => 'No reports available';

  @override
  String get reportRun => 'Run report';

  @override
  String get reportExport => 'Export';

  @override
  String get searchHint => 'Search...';

  @override
  String get searchEmpty => 'Start typing to search';

  @override
  String get searchNoResults => 'No results match your search';
}
