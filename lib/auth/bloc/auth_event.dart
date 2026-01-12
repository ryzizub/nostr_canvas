part of 'auth_bloc.dart';

/// Base class for authentication events.
sealed class AuthEvent {
  const AuthEvent();
}

/// Check for stored credentials on app start.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User chose guest login.
final class AuthGuestRequested extends AuthEvent {
  const AuthGuestRequested();
}

/// User submitted nsec for import.
final class AuthImportRequested extends AuthEvent {
  const AuthImportRequested(this.nsec);

  final String nsec;

  @override
  String toString() => 'AuthImportRequested(nsec: [REDACTED])';
}

/// User chose NIP-07 login.
final class AuthNip07Requested extends AuthEvent {
  const AuthNip07Requested();
}

/// User logged out.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Clear error state and return to unauthenticated.
final class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
