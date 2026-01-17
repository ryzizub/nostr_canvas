import 'package:shared_preferences/shared_preferences.dart';

/// Repository for persisting relay settings using SharedPreferences.
class RelaySettingsRepository {
  /// Creates a [RelaySettingsRepository].
  ///
  /// Optionally accepts a [SharedPreferences] instance for testing.
  RelaySettingsRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _key = 'relay_urls';

  /// Default relay URL.
  static const defaultRelay = 'wss://relay.ryzizub.com';

  /// Initialize with SharedPreferences instance.
  ///
  /// Must be called before using other methods if a SharedPreferences
  /// instance was not provided in the constructor.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the list of saved relay URLs.
  ///
  /// Returns list with [defaultRelay] if none saved.
  List<String> getRelays() {
    final saved = _prefs?.getStringList(_key);
    if (saved == null || saved.isEmpty) {
      return [defaultRelay];
    }
    return saved;
  }

  /// Save relay URLs.
  Future<void> saveRelays(List<String> urls) async {
    await _prefs?.setStringList(_key, urls);
  }

  /// Add a relay URL.
  ///
  /// Does nothing if the relay already exists.
  Future<void> addRelay(String url) async {
    final current = getRelays();
    if (!current.contains(url)) {
      await saveRelays([...current, url]);
    }
  }

  /// Remove a relay URL.
  ///
  /// Ensures at least [defaultRelay] remains if all relays are removed.
  Future<void> removeRelay(String url) async {
    final current = List<String>.from(getRelays())..remove(url);
    if (current.isEmpty) {
      current.add(defaultRelay);
    }
    await saveRelays(current);
  }

  /// Reset to default relay only.
  Future<void> reset() async {
    await saveRelays([defaultRelay]);
  }
}
