import 'package:auth_repository/src/models/auth_method.dart';
import 'package:equatable/equatable.dart';

/// Authenticated user data returned from successful login.
class AuthUser extends Equatable {
  const AuthUser({
    required this.publicKey,
    required this.method,
  });

  /// User's public key in hex format.
  final String publicKey;

  /// How the user authenticated.
  final AuthMethod method;

  @override
  List<Object?> get props => [publicKey, method];
}
