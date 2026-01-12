import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:nostr/nostr.dart' show Event;
import 'package:nostr_client/src/signer/nostr_signer.dart';
import 'package:nostr_client/src/signer/signer_exceptions.dart';

/// Signer using NIP-07 browser extension (web only).
///
/// Communicates with browser extensions like Alby, nos2x, etc.
/// via the window.nostr JavaScript API.
class Nip07Signer implements NostrSigner {
  Nip07Signer._({required this.publicKey});

  @override
  final String publicKey;

  /// Checks if NIP-07 extension is available.
  static bool get isAvailable {
    return _windowNostr != null;
  }

  /// Creates a NIP-07 signer by requesting public key from extension.
  ///
  /// Throws [Nip07NotAvailableException] if extension not installed.
  /// Throws [Nip07UserDeniedException] if user denies access.
  /// Throws [Nip07TimeoutException] if request times out.
  static Future<Nip07Signer> create({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!isAvailable) {
      throw const Nip07NotAvailableException();
    }

    try {
      final nostr = _windowNostr!;
      final pubkey = await nostr.getPublicKey().toDart.timeout(timeout);
      return Nip07Signer._(publicKey: pubkey.toDart);
    } on TimeoutException {
      throw const Nip07TimeoutException();
    } on Object catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('denied') ||
          msg.contains('rejected') ||
          msg.contains('cancelled')) {
        throw const Nip07UserDeniedException();
      }
      rethrow;
    }
  }

  @override
  Future<Event> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
    int? createdAt,
  }) async {
    final unsignedEvent = _createUnsignedEvent(
      kind: kind,
      tags: tags,
      content: content,
      createdAt: createdAt ?? _currentUnixTimestamp(),
    );

    try {
      final nostr = _windowNostr!;
      final signedEvent = await nostr.signEvent(unsignedEvent).toDart;
      final json = _jsObjectToMap(signedEvent);
      return Event.fromJson(json);
    } on Object catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('denied') ||
          msg.contains('rejected') ||
          msg.contains('cancelled')) {
        throw const Nip07UserDeniedException();
      }
      rethrow;
    }
  }
}

/// Create unsigned event JS object using JSON parse.
JSObject _createUnsignedEvent({
  required int kind,
  required List<List<String>> tags,
  required String content,
  required int createdAt,
}) {
  // Build the event as a Dart map, then convert to JS via JSON
  final eventMap = <String, dynamic>{
    'kind': kind,
    'tags': tags,
    'content': content,
    'created_at': createdAt,
  };

  // Convert to JSON string then parse as JS object
  final jsonStr = jsonEncode(eventMap);
  return _jsonParse(jsonStr);
}

/// Convert JS object to Dart map using JSON serialization.
Map<String, dynamic> _jsObjectToMap(JSObject obj) {
  final jsonStr = _stringify(obj);
  return jsonDecode(jsonStr) as Map<String, dynamic>;
}

/// Get current Unix timestamp in seconds.
int _currentUnixTimestamp() {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

// JS interop bindings

/// JSON.stringify binding
@JS('JSON.stringify')
external String _stringify(JSObject obj);

/// JSON.parse binding
@JS('JSON.parse')
external JSObject _jsonParse(String json);

/// Get window.nostr object
@JS('window.nostr')
external _Nip07Extension? get _windowNostr;

/// NIP-07 extension interface
extension type _Nip07Extension._(JSObject _) implements JSObject {
  /// Get public key from extension.
  external JSPromise<JSString> getPublicKey();

  /// Sign an event with the extension.
  external JSPromise<JSObject> signEvent(JSObject event);
}
