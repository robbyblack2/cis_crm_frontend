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

  /// Placeholder label for features not yet implemented.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

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

  /// Section header for a details card.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Section header for an activity timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// Empty-state text when a timeline has no entries.
  ///
  /// In en, this message translates to:
  /// **'No timeline entries'**
  String get noTimelineEntries;

  /// Placeholder text for the record detail timeline section.
  ///
  /// In en, this message translates to:
  /// **'Activity timeline coming soon'**
  String get activityTimelineComingSoon;

  /// Error text when timeline fails to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load timeline'**
  String get timelineLoadFailed;

  /// Title for the delete record confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// Confirmation text for deleting a record.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record? This action cannot be undone.'**
  String get deleteRecordConfirm;

  /// Message when no pipeline stages are loaded.
  ///
  /// In en, this message translates to:
  /// **'No stages available'**
  String get noStagesAvailable;

  /// Label for the move action button.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// Hint text when dragging a record over an empty stage column.
  ///
  /// In en, this message translates to:
  /// **'Drop here'**
  String get dropHere;

  /// Section header for account settings.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Section header for CRM tools in settings.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// Subtitle for automation in settings.
  ///
  /// In en, this message translates to:
  /// **'Rules and workflow automation'**
  String get automationSubtitle;

  /// Subtitle for email templates in settings.
  ///
  /// In en, this message translates to:
  /// **'Manage reusable email templates'**
  String get emailTemplatesSubtitle;

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

  /// Call-to-action when the contacts list is empty.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first contact.'**
  String get contactsEmptyAction;

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

  /// Title for the contact delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete contact?'**
  String get contactDeleteTitle;

  /// Confirmation message before deleting a named contact.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String contactDeleteConfirmName(String name);

  /// Snackbar message after successfully deleting a contact.
  ///
  /// In en, this message translates to:
  /// **'Contact deleted'**
  String get contactDeleted;

  /// Snackbar message when contact deletion fails.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {message}'**
  String contactDeleteFailed(String message);

  /// Button label for adding a new contact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// Tooltip for the edit contact button.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get editContact;

  /// Tooltip for the delete contact button.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get deleteContact;

  /// Tooltip for the floating action button to add a contact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContactTooltip;

  /// Tooltip for clearing the search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Tooltip for the back navigation button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Title when a search yields no results.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResultsTitle;

  /// Body text when a search yields no results.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term.'**
  String get searchNoResultsMessage;

  /// Label for the contact company field.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get contactCompany;

  /// Contact status label for active contacts.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get contactStatusActive;

  /// Contact status label for inactive contacts.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get contactStatusInactive;

  /// Contact status label for leads.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get contactStatusLead;

  /// Contact status label for prospects.
  ///
  /// In en, this message translates to:
  /// **'Prospect'**
  String get contactStatusProspect;

  /// Contact status label for customers.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get contactStatusCustomer;

  /// Error title when contacts fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contacts'**
  String get failedToLoadContacts;

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

  /// Loading label when pipeline is initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing pipeline...'**
  String get pipelineInitializing;

  /// Loading label when pipelines are being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading pipelines...'**
  String get pipelineLoading;

  /// Error title when pipelines fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load pipelines'**
  String get failedToLoadPipelines;

  /// Button and dialog title for creating a new pipeline record.
  ///
  /// In en, this message translates to:
  /// **'New Record'**
  String get newRecord;

  /// Tooltip for the new record floating action button.
  ///
  /// In en, this message translates to:
  /// **'Add a new record'**
  String get addNewRecord;

  /// Hint text for the record title input field.
  ///
  /// In en, this message translates to:
  /// **'Enter record title'**
  String get enterRecordTitle;

  /// Label for the pipeline stage field.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stage;

  /// Empty-state title when a pipeline has no stages.
  ///
  /// In en, this message translates to:
  /// **'No stages configured'**
  String get noStagesConfigured;

  /// Empty-state body when a pipeline has no stages.
  ///
  /// In en, this message translates to:
  /// **'Add stages to this pipeline to start tracking records.'**
  String get noStagesConfiguredMessage;

  /// Empty-state text for a Kanban column with no records.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

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

  /// Generic label for a pipeline record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// Message when a pipeline record cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Record not found'**
  String get recordNotFound;

  /// Menu item label for moving a record to another stage.
  ///
  /// In en, this message translates to:
  /// **'Move to stage'**
  String get moveToStage;

  /// Tooltip for the more actions popup menu.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// Label for the pipeline field on record detail.
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get pipeline;

  /// Label for the contact field on record detail.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Label for the owner field on record detail.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// Label for the source field.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// Label for the created date field.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// Label for the updated date field.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// Generic title field label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

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

  /// Call-to-action when the tasks list is empty.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first task.'**
  String get tasksEmptyAction;

  /// Loading label when tasks are being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading tasks...'**
  String get tasksLoading;

  /// Error title when tasks fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tasks'**
  String get failedToLoadTasks;

  /// Dialog title for creating a new task.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// Hint text for the task title input field.
  ///
  /// In en, this message translates to:
  /// **'Enter task title'**
  String get enterTaskTitle;

  /// Label for the priority field.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// Tooltip for the floating action button to add a task.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// Label for the filter chip that shows all items.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Label for the filter chip for to-do tasks.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get filterTodo;

  /// Label for the filter chip for in-progress tasks.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get filterInProgress;

  /// Label for the filter chip for done tasks.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filterDone;

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

  /// Loading label when calendar events are being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading calendar...'**
  String get calendarLoading;

  /// Error title when the calendar fails to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load calendar'**
  String get failedToLoadCalendar;

  /// Button label to jump to today's date in the calendar.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// Tooltip for the go-to-today button.
  ///
  /// In en, this message translates to:
  /// **'Go to today'**
  String get goToToday;

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

  /// Dialog title for creating a new calendar event.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// Hint text for the event title input field.
  ///
  /// In en, this message translates to:
  /// **'Enter event title'**
  String get enterEventTitle;

  /// Label for the event start date/time field.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Label for the event end date/time field.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// Tooltip for the floating action button to create an event.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get createEventTooltip;

  /// Empty-state title when there are no calendar events.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get noEvents;

  /// Call-to-action when there are no calendar events.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first event.'**
  String get noEventsMessage;

  /// Page title for the event detail view.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

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

  /// Label for a linked pipeline record on an event.
  ///
  /// In en, this message translates to:
  /// **'Linked Record'**
  String get linkedRecord;

  /// Page title for the products view.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// Loading label when products are being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading products…'**
  String get productsLoading;

  /// Error title when products fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get failedToLoadProducts;

  /// Empty-state title when the product catalog is empty.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get productsEmpty;

  /// Call-to-action when the product catalog is empty.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first product.'**
  String get productsEmptyMessage;

  /// Tooltip for the floating action button to add a product.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

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

  /// Loading label when subscriptions are being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading subscriptions…'**
  String get subscriptionsLoading;

  /// Error title when subscriptions fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subscriptions'**
  String get failedToLoadSubscriptions;

  /// Empty-state title when there are no subscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions'**
  String get subscriptionsEmpty;

  /// Body text when there are no subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions will appear here.'**
  String get subscriptionsEmptyMessage;

  /// Page title for the standalone subscriptions page.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptionsPageTitle;

  /// Message when subscriptions have not been loaded yet.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions loaded.'**
  String get noSubscriptionsLoaded;

  /// Page title for the subscription detail view.
  ///
  /// In en, this message translates to:
  /// **'Subscription {systemId}'**
  String subscriptionTitle(String systemId);

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

  /// Label for the product default price field.
  ///
  /// In en, this message translates to:
  /// **'Default Price'**
  String get productDefaultPrice;

  /// Label for the product status field.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get productStatus;

  /// Short label for the product name in detail view.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get productNameLabel;

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

  /// Label for the subscription company field.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get subscriptionCompany;

  /// Label for the subscription product type field.
  ///
  /// In en, this message translates to:
  /// **'Product Type'**
  String get subscriptionProductType;

  /// Generic status field label.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Section header for subscription line items.
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get lineItems;

  /// Empty-state text when there are no line items.
  ///
  /// In en, this message translates to:
  /// **'No line items'**
  String get noLineItems;

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

  /// Page title for the email compose view.
  ///
  /// In en, this message translates to:
  /// **'Compose Email'**
  String get emailComposeTitle;

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

  /// Snackbar message after successfully sending an email.
  ///
  /// In en, this message translates to:
  /// **'Email sent successfully'**
  String get emailSentSuccess;

  /// Snackbar message after successfully saving a draft.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get draftSaved;

  /// Tooltip for the save draft button.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraftTooltip;

  /// Tooltip for the send email button.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get sendEmailTooltip;

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

  /// Hint text for the email recipient field.
  ///
  /// In en, this message translates to:
  /// **'recipient@example.com'**
  String get emailToHint;

  /// Validation error when the email recipient is empty.
  ///
  /// In en, this message translates to:
  /// **'Recipient is required'**
  String get emailRecipientRequired;

  /// Label for the email subject field.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get emailSubject;

  /// Validation error when the email subject is empty.
  ///
  /// In en, this message translates to:
  /// **'Subject is required'**
  String get emailSubjectRequired;

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

  /// Page title for the email templates view.
  ///
  /// In en, this message translates to:
  /// **'Email Templates'**
  String get emailTemplatesTitle;

  /// Empty-state text when there are no email templates.
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get emailTemplatesEmpty;

  /// Empty-state title when there are no email templates.
  ///
  /// In en, this message translates to:
  /// **'No templates'**
  String get emailTemplatesEmptyTitle;

  /// Empty-state body when there are no email templates.
  ///
  /// In en, this message translates to:
  /// **'Create your first email template.'**
  String get emailTemplatesEmptyMessage;

  /// Error title when email templates fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load templates'**
  String get failedToLoadTemplates;

  /// Tooltip for the floating action button to create a template.
  ///
  /// In en, this message translates to:
  /// **'Create template'**
  String get createTemplate;

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

  /// Empty-state title when there are no files.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get filesEmptyTitle;

  /// Empty-state body when there are no files.
  ///
  /// In en, this message translates to:
  /// **'Upload your first file to get started.'**
  String get filesEmptyMessage;

  /// Empty-state title when no parent entity is selected for files.
  ///
  /// In en, this message translates to:
  /// **'No parent context'**
  String get filesNoParentContext;

  /// Message prompting the user to select a parent entity.
  ///
  /// In en, this message translates to:
  /// **'Select a contact or record to view its files.'**
  String get filesSelectParent;

  /// Error title when files fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load files'**
  String get failedToLoadFiles;

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

  /// Button label for opening a file preview.
  ///
  /// In en, this message translates to:
  /// **'Open Preview'**
  String get openPreview;

  /// Label showing who uploaded a file.
  ///
  /// In en, this message translates to:
  /// **'Uploaded by {name}'**
  String uploadedBy(String name);

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

  /// Empty-state body when there are no automation rules.
  ///
  /// In en, this message translates to:
  /// **'Create your first automation rule.'**
  String get automationEmptyMessage;

  /// Error title when automation rules fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load rules'**
  String get failedToLoadRules;

  /// Tooltip for the floating action button to create an automation rule.
  ///
  /// In en, this message translates to:
  /// **'Create rule'**
  String get createRule;

  /// Page title for the automation rule detail view.
  ///
  /// In en, this message translates to:
  /// **'Rule Detail'**
  String get ruleDetail;

  /// Placeholder text for the rule detail page.
  ///
  /// In en, this message translates to:
  /// **'Detail for rule {ruleId} — coming soon.'**
  String ruleDetailComingSoon(String ruleId);

  /// Tooltip when an automation rule is active and can be deactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivate rule'**
  String get deactivateRule;

  /// Tooltip when an automation rule is inactive and can be activated.
  ///
  /// In en, this message translates to:
  /// **'Activate rule'**
  String get activateRule;

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

  /// Label for a partially failed automation execution.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get executionPartial;

  /// Label for a failed automation execution.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get executionFailed;

  /// Label for a dry-run automation execution.
  ///
  /// In en, this message translates to:
  /// **'Dry Run'**
  String get executionDryRun;

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

  /// Empty-state title when there are no reports.
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get reportsEmptyTitle;

  /// Empty-state body when there are no reports.
  ///
  /// In en, this message translates to:
  /// **'Reports will appear here once created.'**
  String get reportsEmptyMessage;

  /// Loading label when reports are being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading reports…'**
  String get reportsLoading;

  /// Error title when reports fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reports'**
  String get failedToLoadReports;

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

  /// Tooltip for the export report button.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get exportReport;

  /// Snackbar message when export is not yet available.
  ///
  /// In en, this message translates to:
  /// **'Export not yet implemented'**
  String get exportNotImplemented;

  /// Loading label when a report is being run.
  ///
  /// In en, this message translates to:
  /// **'Running report…'**
  String get runningReport;

  /// Error title when a report run fails.
  ///
  /// In en, this message translates to:
  /// **'Report failed'**
  String get reportFailed;

  /// Empty-state text when a report returns no data.
  ///
  /// In en, this message translates to:
  /// **'No data returned'**
  String get noDataReturned;

  /// Page title for the settings view.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Page title for the profile view and settings label.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Page title for the integrations view.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrationsTitle;

  /// Section header for security settings.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Section header for user preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// Label for the change password setting.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Label for the timezone setting.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// Label for the calendar filters setting.
  ///
  /// In en, this message translates to:
  /// **'Calendar Filters'**
  String get calendarFilters;

  /// Title for the Google Workspace integration card.
  ///
  /// In en, this message translates to:
  /// **'Google Workspace'**
  String get googleWorkspace;

  /// Description for the Google Workspace integration.
  ///
  /// In en, this message translates to:
  /// **'Connect Gmail, Calendar, and Contacts'**
  String get googleWorkspaceDescription;

  /// Status label for a connected integration.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Status label for a disconnected integration.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// Button label for disconnecting an integration.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Button and dialog title for connecting a Google account.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Account'**
  String get connectGoogleAccount;

  /// Instructions for connecting a Google account via OAuth.
  ///
  /// In en, this message translates to:
  /// **'Copy the link below and open it in your browser to authorize your Google account:'**
  String get connectGoogleInstructions;

  /// Button label for copying a link to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// Snackbar message after a link is copied to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// Label showing the last sync time for an integration.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {dateTime}'**
  String lastSynced(String dateTime);

  /// Page title for the call log view.
  ///
  /// In en, this message translates to:
  /// **'Call Log'**
  String get callLogTitle;

  /// Loading label when call logs are being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading call logs...'**
  String get callLogLoading;

  /// Error title when call logs fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load call logs'**
  String get failedToLoadCallLogs;

  /// Empty-state title when the call log is empty.
  ///
  /// In en, this message translates to:
  /// **'No call logs'**
  String get callLogEmpty;

  /// Call-to-action when the call log is empty.
  ///
  /// In en, this message translates to:
  /// **'Tap + to log your first call.'**
  String get callLogEmptyMessage;

  /// Tooltip for the floating action button to log a call.
  ///
  /// In en, this message translates to:
  /// **'Log a call'**
  String get logCall;

  /// Call outcome label for a connected call.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get callOutcomeConnected;

  /// Call outcome label for a voicemail.
  ///
  /// In en, this message translates to:
  /// **'Voicemail'**
  String get callOutcomeVoicemail;

  /// Call outcome label for a no-answer call.
  ///
  /// In en, this message translates to:
  /// **'No Answer'**
  String get callOutcomeNoAnswer;

  /// Call outcome label for a busy call.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get callOutcomeBusy;

  /// Label for the product currency field.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get productCurrency;

  /// Label for the product tags field.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma-separated)'**
  String get productTags;

  /// Label for the email template name field.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateName;

  /// Label for the email template subject field.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get templateSubject;

  /// Label for the email template body field.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get templateBody;

  /// Label for the automation rule name field.
  ///
  /// In en, this message translates to:
  /// **'Rule name'**
  String get ruleName;

  /// Label for the automation rule description field.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get ruleDescription;

  /// Label for the automation rule trigger type field.
  ///
  /// In en, this message translates to:
  /// **'Trigger type'**
  String get ruleTriggerType;

  /// Label for the automation rule priority field.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get rulePriority;

  /// Label for the contact ID field in call log form.
  ///
  /// In en, this message translates to:
  /// **'Contact ID'**
  String get callContactId;

  /// Label for the call direction field.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get callDirection;

  /// Label for the call outcome field.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get callOutcome;

  /// Label for the call duration field.
  ///
  /// In en, this message translates to:
  /// **'Duration (seconds)'**
  String get callDuration;

  /// Label for the call notes field.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get callNotes;

  /// Title for the pipeline selection dialog.
  ///
  /// In en, this message translates to:
  /// **'Select Pipeline'**
  String get selectPipeline;

  /// Message when no pipelines exist.
  ///
  /// In en, this message translates to:
  /// **'No pipelines available'**
  String get noPipelinesAvailable;

  /// Title for the initial search state.
  ///
  /// In en, this message translates to:
  /// **'Search your CRM'**
  String get searchCrmTitle;

  /// Body text for the initial search state.
  ///
  /// In en, this message translates to:
  /// **'Find contacts, deals, files, and more.'**
  String get searchCrmMessage;

  /// Hint text for the search input field.
  ///
  /// In en, this message translates to:
  /// **'Search contacts, deals, files...'**
  String get searchFieldHint;

  /// Error title when a search fails.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

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

  /// Empty-state message when search yields no results for a specific query.
  ///
  /// In en, this message translates to:
  /// **'No matches found for \"{query}\".'**
  String searchNoMatchesFor(String query);

  /// Generic error message with a prefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);
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
