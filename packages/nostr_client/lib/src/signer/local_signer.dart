import 'package:nostr/nostr.dart' show Event, Keychain;
import 'package:nostr_client/src/signer/nostr_signer.dart';

/// Signer using a local private key (Keychain).
///
/// Used for guest accounts (generated keys) and imported keys.
class LocalSigner implements NostrSigner {
  /// Creates a LocalSigner from an existing keychain.
  LocalSigner({required this.keychain});

  /// Creates a LocalSigner by generating a new random keypair.
  factory LocalSigner.generate() {
    return LocalSigner(keychain: Keychain.generate());
  }

  /// Creates a LocalSigner from a private key hex string.
  factory LocalSigner.fromPrivateKeyHex(String privateKeyHex) {
    return LocalSigner(keychain: Keychain(privateKeyHex));
  }

  /// The keychain containing the private key.
  final Keychain keychain;

  @override
  String get publicKey => keychain.public;

  /// The private key in hex format.
  String get privateKey => keychain.private;

  @override
  Future<Event> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
    int? createdAt,
  }) async {
    // Sync signing wrapped in Future for uniform API
    return Event.from(
      kind: kind,
      tags: tags,
      content: content,
      privkey: keychain.private,
      createdAt: createdAt,
    );
  }
}
