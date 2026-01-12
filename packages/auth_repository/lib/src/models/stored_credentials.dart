/// Credentials stored in secure storage.
class StoredCredentials {
  const StoredCredentials({
    required this.method,
    required this.publicKey,
    this.privateKey,
  });

  /// Authentication method used ('guest', 'imported', or 'nip07').
  final String method;

  /// User's public key in hex format.
  final String publicKey;

  /// User's private key in hex format (null for NIP-07).
  final String? privateKey;
}
