import 'package:nostr/nostr.dart' show Event;

/// Abstract signer interface for Nostr event signing.
///
/// Implementations handle both local private key signing
/// and NIP-07 browser extension signing.
abstract class NostrSigner {
  /// The public key (hex format) for this signer.
  String get publicKey;

  /// Signs an event and returns the signed event.
  ///
  /// Takes event parameters and returns the complete signed event.
  Future<Event> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
    int? createdAt,
  });
}
