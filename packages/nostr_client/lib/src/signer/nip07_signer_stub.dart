import 'package:nostr/nostr.dart' show Event;
import 'package:nostr_client/src/signer/nostr_signer.dart';
import 'package:nostr_client/src/signer/signer_exceptions.dart';

/// Stub implementation of NIP-07 signer for non-web platforms.
///
/// NIP-07 is only available in web browsers with extensions.
class Nip07Signer implements NostrSigner {
  Nip07Signer._({required this.publicKey});

  @override
  final String publicKey;

  /// Always returns false on non-web platforms.
  static bool get isAvailable => false;

  /// Always throws [Nip07NotAvailableException] on non-web platforms.
  static Future<Nip07Signer> create({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    throw const Nip07NotAvailableException();
  }

  @override
  Future<Event> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
    int? createdAt,
  }) async {
    throw const Nip07NotAvailableException();
  }
}
