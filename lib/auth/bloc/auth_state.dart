part of 'auth_bloc.dart';

/// Authentication status.
enum AuthStatus {
  /// Initial state, checking for existing session.
  initial,

  /// No session, show login screen.
  unauthenticated,

  /// Login in progress.
  authenticating,

  /// Authenticated, can proceed to canvas.
  authenticated,

  /// Authentication failed.
  error,
}

/// Authentication state.
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.method,
    this.publicKey,
    this.errorMessage,
  });

  /// Current authentication status.
  final AuthStatus status;

  /// How the user authenticated (null if not authenticated).
  final AuthMethod? method;

  /// User's public key in hex format (null if not authenticated).
  final String? publicKey;

  /// Error message (only set when status is error).
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AuthMethod? method,
    String? publicKey,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      method: method ?? this.method,
      publicKey: publicKey ?? this.publicKey,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, method, publicKey, errorMessage];
}
