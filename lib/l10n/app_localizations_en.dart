// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get loginButton => 'Login';

  @override
  String get usernamePlaceholder => 'Name, phone number or email address';

  @override
  String get passwordPlaceholder => 'Password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign up';

  @override
  String get privacyPolicy =>
      'All rights reserved | Privacy Policy | Cookies | Powered by';
}
