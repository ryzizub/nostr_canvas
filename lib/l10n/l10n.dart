import 'package:flutter/widgets.dart';
import 'package:nostr_place/l10n/gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Extension on [BuildContext] to provide easy access to [AppLocalizations].
extension AppLocalizationsX on BuildContext {
  /// Returns the [AppLocalizations] instance for this context.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
