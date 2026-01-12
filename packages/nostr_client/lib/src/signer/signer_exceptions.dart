/// Base exception for signer-related errors.
sealed class SignerException implements Exception {
  const SignerException(this.message);

  /// Error message describing what went wrong.
  final String message;

  @override
  String toString() => message;
}

/// Thrown when NIP-07 browser extension is not installed.
class Nip07NotAvailableException extends SignerException {
  const Nip07NotAvailableException()
      : super('NIP-07 browser extension not installed');
}

/// Thrown when user denies NIP-07 signing request.
class Nip07UserDeniedException extends SignerException {
  const Nip07UserDeniedException()
      : super('User denied NIP-07 signing request');
}

/// Thrown when NIP-07 request times out.
class Nip07TimeoutException extends SignerException {
  const Nip07TimeoutException() : super('NIP-07 request timed out');
}

/// Thrown when nsec key format is invalid.
class InvalidNsecException extends SignerException {
  const InvalidNsecException(super.message);
}
