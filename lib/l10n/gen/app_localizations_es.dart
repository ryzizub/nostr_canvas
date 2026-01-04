// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Nostr Place';

  @override
  String get welcomeTitle => 'Nostr Place';

  @override
  String get welcomeSubtitle => 'Lienzo Colaborativo de Píxeles';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Ocurrió un error';

  @override
  String get retry => 'Reintentar';
}
