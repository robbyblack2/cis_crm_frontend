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
  String get comingSoon => 'Coming soon';

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
  String get details => 'Details';

  @override
  String get timeline => 'Timeline';

  @override
  String get noTimelineEntries => 'No timeline entries';

  @override
  String get activityTimelineComingSoon => 'Activity timeline coming soon';

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
  String get contactsEmptyAction =>
      'Tap the + button to add your first contact.';

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
  String get contactDeleteTitle => 'Delete contact?';

  @override
  String contactDeleteConfirmName(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get contactDeleted => 'Contact deleted';

  @override
  String contactDeleteFailed(String message) {
    return 'Delete failed: $message';
  }

  @override
  String get addContact => 'Add Contact';

  @override
  String get editContact => 'Edit contact';

  @override
  String get deleteContact => 'Delete contact';

  @override
  String get addContactTooltip => 'Add contact';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get back => 'Back';

  @override
  String get searchNoResultsTitle => 'No results';

  @override
  String get searchNoResultsMessage => 'Try a different search term.';

  @override
  String get contactCompany => 'Company';

  @override
  String get contactStatusActive => 'Active';

  @override
  String get contactStatusInactive => 'Inactive';

  @override
  String get contactStatusLead => 'Lead';

  @override
  String get contactStatusProspect => 'Prospect';

  @override
  String get contactStatusCustomer => 'Customer';

  @override
  String get failedToLoadContacts => 'Failed to load contacts';

  @override
  String get pipelineTitle => 'Pipeline';

  @override
  String get pipelineEmpty => 'No deals in your pipeline';

  @override
  String get pipelineInitializing => 'Initializing pipeline...';

  @override
  String get pipelineLoading => 'Loading pipelines...';

  @override
  String get failedToLoadPipelines => 'Failed to load pipelines';

  @override
  String get newRecord => 'New Record';

  @override
  String get addNewRecord => 'Add a new record';

  @override
  String get enterRecordTitle => 'Enter record title';

  @override
  String get stage => 'Stage';

  @override
  String get noStagesConfigured => 'No stages configured';

  @override
  String get noStagesConfiguredMessage =>
      'Add stages to this pipeline to start tracking records.';

  @override
  String get noRecords => 'No records';

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
  String get record => 'Record';

  @override
  String get recordNotFound => 'Record not found';

  @override
  String get moveToStage => 'Move to stage';

  @override
  String get moreActions => 'More actions';

  @override
  String get pipeline => 'Pipeline';

  @override
  String get contact => 'Contact';

  @override
  String get owner => 'Owner';

  @override
  String get source => 'Source';

  @override
  String get created => 'Created';

  @override
  String get updated => 'Updated';

  @override
  String get title => 'Title';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksEmpty => 'No tasks yet';

  @override
  String get tasksEmptyMessage => 'Create a task to start tracking your work.';

  @override
  String get tasksEmptyAction => 'Tap + to create your first task.';

  @override
  String get tasksLoading => 'Loading tasks...';

  @override
  String get failedToLoadTasks => 'Failed to load tasks';

  @override
  String get createTask => 'Create Task';

  @override
  String get enterTaskTitle => 'Enter task title';

  @override
  String get priority => 'Priority';

  @override
  String get addTask => 'Add task';

  @override
  String get filterAll => 'All';

  @override
  String get filterTodo => 'Todo';

  @override
  String get filterInProgress => 'In Progress';

  @override
  String get filterDone => 'Done';

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
  String get calendarLoading => 'Loading calendar...';

  @override
  String get failedToLoadCalendar => 'Failed to load calendar';

  @override
  String get calendarToday => 'Today';

  @override
  String get goToToday => 'Go to today';

  @override
  String get viewDay => 'Day';

  @override
  String get viewWeek => 'Week';

  @override
  String get viewMonth => 'Month';

  @override
  String get createEvent => 'Create Event';

  @override
  String get enterEventTitle => 'Enter event title';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get createEventTooltip => 'Create event';

  @override
  String get noEvents => 'No events';

  @override
  String get noEventsMessage => 'Tap + to create your first event.';

  @override
  String get eventDetails => 'Event Details';

  @override
  String get eventTitle => 'Event title';

  @override
  String get eventLocation => 'Location';

  @override
  String get eventMeetingLink => 'Meeting link';

  @override
  String get linkedRecord => 'Linked Record';

  @override
  String get productsTitle => 'Products';

  @override
  String get productsLoading => 'Loading products…';

  @override
  String get failedToLoadProducts => 'Failed to load products';

  @override
  String get productsEmpty => 'No products yet';

  @override
  String get productsEmptyMessage => 'Tap + to add your first product.';

  @override
  String get addProduct => 'Add product';

  @override
  String get catalogTab => 'Catalog';

  @override
  String get subscriptionsTab => 'Subscriptions';

  @override
  String get subscriptionsLoading => 'Loading subscriptions…';

  @override
  String get failedToLoadSubscriptions => 'Failed to load subscriptions';

  @override
  String get subscriptionsEmpty => 'No subscriptions';

  @override
  String get subscriptionsEmptyMessage => 'Subscriptions will appear here.';

  @override
  String get subscriptionsPageTitle => 'Subscriptions';

  @override
  String get noSubscriptionsLoaded => 'No subscriptions loaded.';

  @override
  String subscriptionTitle(String systemId) {
    return 'Subscription $systemId';
  }

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
  String get productDefaultPrice => 'Default Price';

  @override
  String get productStatus => 'Status';

  @override
  String get productNameLabel => 'Name';

  @override
  String get subscriptionSystemId => 'System ID';

  @override
  String get subscriptionStatus => 'Subscription status';

  @override
  String get subscriptionCompany => 'Company';

  @override
  String get subscriptionProductType => 'Product Type';

  @override
  String get status => 'Status';

  @override
  String get lineItems => 'Line Items';

  @override
  String get noLineItems => 'No line items';

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
  String get emailComposeTitle => 'Compose Email';

  @override
  String get emailCompose => 'Compose';

  @override
  String get emailSend => 'Send';

  @override
  String get emailSentSuccess => 'Email sent successfully';

  @override
  String get draftSaved => 'Draft saved';

  @override
  String get saveDraftTooltip => 'Save draft';

  @override
  String get sendEmailTooltip => 'Send email';

  @override
  String get emailSaveDraft => 'Save draft';

  @override
  String get emailTo => 'To';

  @override
  String get emailToHint => 'recipient@example.com';

  @override
  String get emailRecipientRequired => 'Recipient is required';

  @override
  String get emailSubject => 'Subject';

  @override
  String get emailSubjectRequired => 'Subject is required';

  @override
  String get emailBody => 'Body';

  @override
  String get emailTemplates => 'Templates';

  @override
  String get emailTemplatesTitle => 'Email Templates';

  @override
  String get emailTemplatesEmpty => 'No templates available';

  @override
  String get emailTemplatesEmptyTitle => 'No templates';

  @override
  String get emailTemplatesEmptyMessage => 'Create your first email template.';

  @override
  String get failedToLoadTemplates => 'Failed to load templates';

  @override
  String get createTemplate => 'Create template';

  @override
  String get filesTitle => 'Files';

  @override
  String get filesEmpty => 'No files uploaded';

  @override
  String get filesEmptyTitle => 'No files';

  @override
  String get filesEmptyMessage => 'Upload your first file to get started.';

  @override
  String get filesNoParentContext => 'No parent context';

  @override
  String get filesSelectParent =>
      'Select a contact or record to view its files.';

  @override
  String get failedToLoadFiles => 'Failed to load files';

  @override
  String get uploadFile => 'Upload file';

  @override
  String get deleteFile => 'Delete file';

  @override
  String get openPreview => 'Open Preview';

  @override
  String uploadedBy(String name) {
    return 'Uploaded by $name';
  }

  @override
  String get automationTitle => 'Automation';

  @override
  String get automationEmpty => 'No automation rules';

  @override
  String get automationEmptyMessage => 'Create your first automation rule.';

  @override
  String get failedToLoadRules => 'Failed to load rules';

  @override
  String get createRule => 'Create rule';

  @override
  String get ruleDetail => 'Rule Detail';

  @override
  String ruleDetailComingSoon(String ruleId) {
    return 'Detail for rule $ruleId — coming soon.';
  }

  @override
  String get deactivateRule => 'Deactivate rule';

  @override
  String get activateRule => 'Activate rule';

  @override
  String get automationRuleActive => 'Active';

  @override
  String get automationRuleInactive => 'Inactive';

  @override
  String get executionLog => 'Execution log';

  @override
  String get executionSuccess => 'Success';

  @override
  String get executionPartial => 'Partial';

  @override
  String get executionFailed => 'Failed';

  @override
  String get executionDryRun => 'Dry Run';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsEmpty => 'No reports available';

  @override
  String get reportsEmptyTitle => 'No reports';

  @override
  String get reportsEmptyMessage => 'Reports will appear here once created.';

  @override
  String get reportsLoading => 'Loading reports…';

  @override
  String get failedToLoadReports => 'Failed to load reports';

  @override
  String get reportRun => 'Run report';

  @override
  String get reportExport => 'Export';

  @override
  String get exportReport => 'Export report';

  @override
  String get exportNotImplemented => 'Export not yet implemented';

  @override
  String get runningReport => 'Running report…';

  @override
  String get reportFailed => 'Report failed';

  @override
  String get noDataReturned => 'No data returned';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileTitle => 'Profile';

  @override
  String get integrationsTitle => 'Integrations';

  @override
  String get security => 'Security';

  @override
  String get preferences => 'Preferences';

  @override
  String get changePassword => 'Change Password';

  @override
  String get timezone => 'Timezone';

  @override
  String get calendarFilters => 'Calendar Filters';

  @override
  String get googleWorkspace => 'Google Workspace';

  @override
  String get googleWorkspaceDescription =>
      'Connect Gmail, Calendar, and Contacts';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connectGoogleAccount => 'Connect Google Account';

  @override
  String get connectGoogleInstructions =>
      'Copy the link below and open it in your browser to authorize your Google account:';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String lastSynced(String dateTime) {
    return 'Last synced: $dateTime';
  }

  @override
  String get callLogTitle => 'Call Log';

  @override
  String get callLogLoading => 'Loading call logs...';

  @override
  String get failedToLoadCallLogs => 'Failed to load call logs';

  @override
  String get callLogEmpty => 'No call logs';

  @override
  String get callLogEmptyMessage => 'Tap + to log your first call.';

  @override
  String get logCall => 'Log a call';

  @override
  String get callOutcomeConnected => 'Connected';

  @override
  String get callOutcomeVoicemail => 'Voicemail';

  @override
  String get callOutcomeNoAnswer => 'No Answer';

  @override
  String get callOutcomeBusy => 'Busy';

  @override
  String get searchCrmTitle => 'Search your CRM';

  @override
  String get searchCrmMessage => 'Find contacts, deals, files, and more.';

  @override
  String get searchFieldHint => 'Search contacts, deals, files...';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get searchHint => 'Search...';

  @override
  String get searchEmpty => 'Start typing to search';

  @override
  String get searchNoResults => 'No results match your search';

  @override
  String searchNoMatchesFor(String query) {
    return 'No matches found for \"$query\".';
  }

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }
}
