/// How the user authenticated.
enum AuthMethod {
  /// Generated a new random key.
  guest,

  /// Imported an existing nsec key.
  imported,

  /// Using NIP-07 browser extension.
  nip07,
}
