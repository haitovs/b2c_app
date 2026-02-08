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

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @usernamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Number or Email Address'**
  String get usernamePlaceholder;

  /// No description provided for @passwordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordPlaceholder;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved | Privacy Policy | Cookies | Powered by'**
  String get privacyPolicy;

  /// No description provided for @registrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registrationTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get nameLabel;

  /// No description provided for @namePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get namePlaceholder;

  /// No description provided for @surnameLabel.
  ///
  /// In en, this message translates to:
  /// **'Surname:'**
  String get surnameLabel;

  /// No description provided for @surnamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surnamePlaceholder;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address:'**
  String get emailLabel;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'email@gmail.com'**
  String get emailPlaceholder;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number:'**
  String get mobileLabel;

  /// No description provided for @mobilePlaceholder.
  ///
  /// In en, this message translates to:
  /// **''**
  String get mobilePlaceholder;

  /// No description provided for @websiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Website:'**
  String get websiteLabel;

  /// No description provided for @websitePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'mycompany.com'**
  String get websitePlaceholder;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name:'**
  String get companyNameLabel;

  /// No description provided for @companyNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyNamePlaceholder;

  /// No description provided for @registrationButton.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registrationButton;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by event name'**
  String get searchPlaceholder;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @startingIn.
  ///
  /// In en, this message translates to:
  /// **'Starting in:'**
  String get startingIn;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @mentions.
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get mentions;

  /// No description provided for @openButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openButton;

  /// No description provided for @speakersLabel.
  ///
  /// In en, this message translates to:
  /// **'Speakers'**
  String get speakersLabel;

  /// No description provided for @keyThemesLabel.
  ///
  /// In en, this message translates to:
  /// **'Key Themes of the Forum:'**
  String get keyThemesLabel;

  /// No description provided for @dearParticipants.
  ///
  /// In en, this message translates to:
  /// **'Dear Participants!'**
  String get dearParticipants;

  /// No description provided for @agenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get agenda;

  /// No description provided for @speakers.
  ///
  /// In en, this message translates to:
  /// **'Speakers'**
  String get speakers;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @meetings.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get meetings;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @myParticipants.
  ///
  /// In en, this message translates to:
  /// **'My participants'**
  String get myParticipants;

  /// No description provided for @flights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get flights;

  /// No description provided for @accommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get accommodation;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @hotline.
  ///
  /// In en, this message translates to:
  /// **'Hotline'**
  String get hotline;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @goldSponsor.
  ///
  /// In en, this message translates to:
  /// **'Gold Sponsor'**
  String get goldSponsor;

  /// No description provided for @program.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get program;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @searchByEventName.
  ///
  /// In en, this message translates to:
  /// **'Search by event name'**
  String get searchByEventName;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @moderator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get moderator;

  /// No description provided for @topic.
  ///
  /// In en, this message translates to:
  /// **'Topic:'**
  String get topic;

  /// No description provided for @forumHall.
  ///
  /// In en, this message translates to:
  /// **'Forum Hall'**
  String get forumHall;

  /// No description provided for @presentationHall.
  ///
  /// In en, this message translates to:
  /// **'Presentation Hall'**
  String get presentationHall;

  /// No description provided for @hall50A.
  ///
  /// In en, this message translates to:
  /// **'Hall 50A'**
  String get hall50A;

  /// No description provided for @hall50B.
  ///
  /// In en, this message translates to:
  /// **'Hall 50B'**
  String get hall50B;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get terms;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password:'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password:'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordPlaceholder;

  /// No description provided for @eventNotFound.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get eventNotFound;

  /// No description provided for @speakerBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speakerBreadcrumb;

  /// No description provided for @keyThemesTurkmenistanChina.
  ///
  /// In en, this message translates to:
  /// **'Key Themes of the Turkmenistan–China Forum:'**
  String get keyThemesTurkmenistanChina;

  /// No description provided for @participantInstructions.
  ///
  /// In en, this message translates to:
  /// **'To access the mobile application, please click the button below. If you do not find yourself in the list of participants, please complete your registration on the official website. Your personal ID will be sent to the email address you provided.'**
  String get participantInstructions;

  /// No description provided for @eventMenu.
  ///
  /// In en, this message translates to:
  /// **'Event Menu'**
  String get eventMenu;

  /// No description provided for @silverSponsor.
  ///
  /// In en, this message translates to:
  /// **'Silver Sponsor'**
  String get silverSponsor;

  /// No description provided for @bronzeSponsor.
  ///
  /// In en, this message translates to:
  /// **'Bronze Sponsor'**
  String get bronzeSponsor;

  /// No description provided for @partner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get partner;

  /// No description provided for @mediaPartner.
  ///
  /// In en, this message translates to:
  /// **'Media Partner'**
  String get mediaPartner;

  /// No description provided for @annualExpoTitle.
  ///
  /// In en, this message translates to:
  /// **'Annual Expo CMR forum for international guests'**
  String get annualExpoTitle;

  /// No description provided for @eventMenuLine1.
  ///
  /// In en, this message translates to:
  /// **'Annual Expo CMR forum for'**
  String get eventMenuLine1;

  /// No description provided for @eventMenuLine2.
  ///
  /// In en, this message translates to:
  /// **'international guests'**
  String get eventMenuLine2;

  /// No description provided for @exitEvent.
  ///
  /// In en, this message translates to:
  /// **'Exit Event'**
  String get exitEvent;
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
    'that was used.',
  );
}
