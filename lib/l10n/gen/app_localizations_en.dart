// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nostr Place';

  @override
  String get welcomeTitle => 'Nostr Place';

  @override
  String get welcomeSubtitle => 'Collaborative Pixel Canvas';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'An error occurred';

  @override
  String get retry => 'Retry';
}
