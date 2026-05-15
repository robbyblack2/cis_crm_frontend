import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application title shown in the OS task switcher and on web.
  ///
  /// In en, this message translates to:
  /// **'CIS CRM'**
  String get appTitle;

  /// Generic loading indicator label.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Retry button label on error states.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Dismiss/close button label on banners and dialogs.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @failure_network.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get failure_network;

  /// No description provided for @failure_server.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our end. Please try again in a moment.'**
  String get failure_server;

  /// No description provided for @failure_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get failure_unauthorized;

  /// No description provided for @failure_validation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields and try again.'**
  String get failure_validation;

  /// No description provided for @failure_cache.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read local data. Try restarting the app.'**
  String get failure_cache;

  /// No description provided for @failure_unknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get failure_unknown;

  /// Navigation label for the pipeline/deals view.
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get navPipeline;

  /// Navigation label for the contacts view.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// Navigation label for the tasks view.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// Navigation label for the calendar view.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// Navigation label for the products view.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// Navigation label for the reports view.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// Generic sign-in action label.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Generic sign-out action label.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Generic email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Generic password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Generic search action label.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Generic cancel action label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic save action label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic delete action label.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic edit action label.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Generic create action label.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Generic add action label.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Empty state when a list or search yields zero items.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Title for a delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirmDelete;

  /// Body text for a generic delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item? This action cannot be undone.'**
  String get confirmDeleteMessage;

  /// Title shown on the login page.
  ///
  /// In en, this message translates to:
  /// **'Sign in to CIS CRM'**
  String get loginTitle;

  /// Label for the email field on the login form.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailLabel;

  /// Label for the password field on the login form.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// Primary login submit button label.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// Validation error for a malformed email on the login form.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get loginEmailInvalid;

  /// Validation error when the password is too short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get loginPasswordTooShort;

  /// Page title for the contacts list.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// Empty-state title when the contacts list is empty.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contactsEmpty;

  /// Empty-state body when the contacts list is empty.
  ///
  /// In en, this message translates to:
  /// **'Add your first contact to get started.'**
  String get contactsEmptyMessage;

  /// Placeholder text for the contacts search field.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get contactSearch;

  /// Label for contact first name field.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get contactFirstName;

  /// Label for contact last name field.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get contactLastName;

  /// Label for contact email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// Label for contact phone field.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhone;

  /// Label for contact job title field.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get contactJobTitle;

  /// Label for contact lead-source field.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get contactSource;

  /// Label for contact status field.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get contactStatus;

  /// Label for contact tags field.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get contactTags;

  /// Confirmation message before deleting a contact.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this contact?'**
  String get contactDeleteConfirm;

  /// Page title for the pipeline/deals view.
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get pipelineTitle;

  /// Empty-state text when the pipeline has no deals.
  ///
  /// In en, this message translates to:
  /// **'No deals in your pipeline'**
  String get pipelineEmpty;

  /// Button label for creating a new pipeline record/deal.
  ///
  /// In en, this message translates to:
  /// **'Create record'**
  String get recordCreate;

  /// Label for the pipeline record title field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get recordTitle;

  /// Action label for moving a record to another stage.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get recordMove;

  /// Label for viewing the stage transition history of a record.
  ///
  /// In en, this message translates to:
  /// **'Stage history'**
  String get recordStageHistory;

  /// Empty-state text for a Kanban column with no cards.
  ///
  /// In en, this message translates to:
  /// **'No records in this stage'**
  String get kanbanEmpty;

  /// Label for the won/closed-won pipeline stage.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get stageWon;

  /// Label for the lost/closed-lost pipeline stage.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get stageLost;

  /// Page title for the tasks view.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// Empty-state title when the tasks list is empty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get tasksEmpty;

  /// Empty-state body when the tasks list is empty.
  ///
  /// In en, this message translates to:
  /// **'Create a task to start tracking your work.'**
  String get tasksEmptyMessage;

  /// Label for the to-do task status.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get taskTodo;

  /// Label for the in-progress task status.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskInProgress;

  /// Label for the completed task status.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskDone;

  /// Label for low-priority tasks.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get taskPriorityLow;

  /// Label for medium-priority tasks.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get taskPriorityMedium;

  /// Label for high-priority tasks.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get taskPriorityHigh;

  /// Label for the task title field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitle;

  /// Label for the task description field.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskDescription;

  /// Label for the task due-date field.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskDueDate;

  /// Label for the task assignee field.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get taskAssignee;

  /// Page title for the calendar view.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// Empty-state text when the calendar has no events.
  ///
  /// In en, this message translates to:
  /// **'No events scheduled'**
  String get calendarEmpty;

  /// Button label to jump to today's date in the calendar.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// Calendar view selector: day view.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get viewDay;

  /// Calendar view selector: week view.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get viewWeek;

  /// Calendar view selector: month view.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get viewMonth;

  /// Label for the calendar event title field.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get eventTitle;

  /// Label for the calendar event location field.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventLocation;

  /// Label for the calendar event meeting-link field.
  ///
  /// In en, this message translates to:
  /// **'Meeting link'**
  String get eventMeetingLink;

  /// Page title for the products view.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// Tab label for the product catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogTab;

  /// Tab label for the subscriptions list.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptionsTab;

  /// Label for the product name field.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// Label for the product type field.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get productType;

  /// Label for the product price field.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productPrice;

  /// Status label for an active product.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get productActive;

  /// Status label for an inactive product.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get productInactive;

  /// Label for the subscription system-ID field.
  ///
  /// In en, this message translates to:
  /// **'System ID'**
  String get subscriptionSystemId;

  /// Label for the subscription status field.
  ///
  /// In en, this message translates to:
  /// **'Subscription status'**
  String get subscriptionStatus;

  /// Subscription status: trialing.
  ///
  /// In en, this message translates to:
  /// **'Trialing'**
  String get statusTrialing;

  /// Subscription status: active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// Subscription status: past due.
  ///
  /// In en, this message translates to:
  /// **'Past due'**
  String get statusPastDue;

  /// Subscription status: paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// Subscription status: cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Subscription status: expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// Button label for composing a new email.
  ///
  /// In en, this message translates to:
  /// **'Compose'**
  String get emailCompose;

  /// Button label for sending an email.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get emailSend;

  /// Button label for saving an email as a draft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get emailSaveDraft;

  /// Label for the email recipient field.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get emailTo;

  /// Label for the email subject field.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get emailSubject;

  /// Label for the email body field.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get emailBody;

  /// Label for the email templates section.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get emailTemplates;

  /// Empty-state text when there are no email templates.
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get emailTemplatesEmpty;

  /// Page title for the files view.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTitle;

  /// Empty-state text when there are no files.
  ///
  /// In en, this message translates to:
  /// **'No files uploaded'**
  String get filesEmpty;

  /// Button label for uploading a file.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get uploadFile;

  /// Button label for deleting a file.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get deleteFile;

  /// Page title for the automation rules view.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get automationTitle;

  /// Empty-state text when there are no automation rules.
  ///
  /// In en, this message translates to:
  /// **'No automation rules'**
  String get automationEmpty;

  /// Status label for an active automation rule.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get automationRuleActive;

  /// Status label for an inactive automation rule.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get automationRuleInactive;

  /// Label for the automation execution log.
  ///
  /// In en, this message translates to:
  /// **'Execution log'**
  String get executionLog;

  /// Label for a successful automation execution.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get executionSuccess;

  /// Label for a failed automation execution.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get executionFailed;

  /// Page title for the reports view.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// Empty-state text when there are no reports.
  ///
  /// In en, this message translates to:
  /// **'No reports available'**
  String get reportsEmpty;

  /// Button label for running/generating a report.
  ///
  /// In en, this message translates to:
  /// **'Run report'**
  String get reportRun;

  /// Button label for exporting a report.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get reportExport;

  /// Hint text for the global search field.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// Placeholder text shown before the user begins typing in search.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search'**
  String get searchEmpty;

  /// Empty-state text when a search returns no results.
  ///
  /// In en, this message translates to:
  /// **'No results match your search'**
  String get searchNoResults;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
