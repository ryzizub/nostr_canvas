import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nostr_client/nostr_client.dart'
    show InvalidNsecException, SignerException;

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc managing authentication state.
///
/// Owns and manages [AuthState] based on [AuthRepository] operations.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGuestRequested>(_onGuestRequested);
    on<AuthImportRequested>(_onImportRequested);
    on<AuthNip07Requested>(_onNip07Requested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthErrorCleared>(_onErrorCleared);
  }

  final AuthRepository _authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.checkStoredCredentials();
      if (user != null) {
        emit(
          AuthState(
            status: AuthStatus.authenticated,
            method: user.method,
            publicKey: user.publicKey,
          ),
        );
      } else {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    } on Object catch (e) {
      emit(
        AuthState(
          status: AuthStatus.error,
          errorMessage: 'Failed to restore session: $e',
        ),
      );
    }
  }

  Future<void> _onGuestRequested(
    AuthGuestRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating));

    try {
      final user = await _authRepository.loginAsGuest();
      emit(
        AuthState(
          status: AuthStatus.authenticated,
          method: user.method,
          publicKey: user.publicKey,
        ),
      );
    } on Object catch (e) {
      emit(
        AuthState(
          status: AuthStatus.error,
          errorMessage: 'Failed to login: $e',
        ),
      );
    }
  }

  Future<void> _onImportRequested(
    AuthImportRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating));

    try {
      final user = await _authRepository.loginWithNsec(event.nsec);
      emit(
        AuthState(
          status: AuthStatus.authenticated,
          method: user.method,
          publicKey: user.publicKey,
        ),
      );
    } on InvalidNsecException catch (e) {
      emit(
        AuthState(
          status: AuthStatus.error,
          errorMessage: e.message,
        ),
      );
    } on Object catch (e) {
      emit(
        AuthState(
          status: AuthStatus.error,
          errorMessage: 'Failed to import key: $e',
        ),
      );
    }
  }

  Future<void> _onNip07Requested(
    AuthNip07Requested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating));

    try {
      final user = await _authRepository.loginWithNip07();
      emit(
        AuthState(
          status: AuthStatus.authenticated,
          method: user.method,
          publicKey: user.publicKey,
        ),
      );
    } on SignerException catch (e) {
      emit(
        AuthState(
          status: AuthStatus.error,
          errorMessage: e.message,
        ),
      );
    } on Object catch (e) {
      emit(
        AuthState(
          status: AuthStatus.error,
          errorMessage: 'Failed to connect with extension: $e',
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _onErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
