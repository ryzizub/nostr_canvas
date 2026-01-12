import 'package:auth_repository/auth_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_client/nostr_client.dart'
    show InvalidNsecException, Nip07NotAvailableException;
import 'package:nostr_place/auth/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthBloc', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    test('initial state is AuthState with initial status', () {
      final bloc = AuthBloc(authRepository: mockAuthRepository);
      expect(bloc.state, const AuthState());
      expect(bloc.state.status, AuthStatus.initial);
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits authenticated when stored credentials exist',
        setUp: () {
          when(() => mockAuthRepository.checkStoredCredentials()).thenAnswer(
            (_) async => const AuthUser(
              publicKey: 'pubkey123',
              method: AuthMethod.guest,
            ),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState(
            status: AuthStatus.authenticated,
            method: AuthMethod.guest,
            publicKey: 'pubkey123',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits unauthenticated when no stored credentials',
        setUp: () {
          when(() => mockAuthRepository.checkStoredCredentials()).thenAnswer(
            (_) async => null,
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthState(status: AuthStatus.unauthenticated),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits error when check credentials fails',
        setUp: () {
          when(() => mockAuthRepository.checkStoredCredentials()).thenThrow(
            Exception('Storage error'),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Failed to restore session'),
              ),
        ],
      );
    });

    group('AuthGuestRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits authenticating then authenticated on success',
        setUp: () {
          when(() => mockAuthRepository.loginAsGuest()).thenAnswer(
            (_) async => const AuthUser(
              publicKey: 'guestpubkey',
              method: AuthMethod.guest,
            ),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthGuestRequested()),
        expect: () => [
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticating,
          ),
          const AuthState(
            status: AuthStatus.authenticated,
            method: AuthMethod.guest,
            publicKey: 'guestpubkey',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits authenticating then error on failure',
        setUp: () {
          when(() => mockAuthRepository.loginAsGuest()).thenThrow(
            Exception('Connection failed'),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthGuestRequested()),
        expect: () => [
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticating,
          ),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Failed to login'),
              ),
        ],
      );
    });

    group('AuthImportRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits authenticating then authenticated on valid nsec',
        setUp: () {
          when(() => mockAuthRepository.loginWithNsec('nsec1valid')).thenAnswer(
            (_) async => const AuthUser(
              publicKey: 'importedpubkey',
              method: AuthMethod.imported,
            ),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthImportRequested('nsec1valid')),
        expect: () => [
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticating,
          ),
          const AuthState(
            status: AuthStatus.authenticated,
            method: AuthMethod.imported,
            publicKey: 'importedpubkey',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits error with message on InvalidNsecException',
        setUp: () {
          when(() => mockAuthRepository.loginWithNsec('invalid')).thenThrow(
            const InvalidNsecException('Invalid nsec format'),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthImportRequested('invalid')),
        expect: () => [
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticating,
          ),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                'Invalid nsec format',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits generic error on other exceptions',
        setUp: () {
          when(() => mockAuthRepository.loginWithNsec('nsec1test')).thenThrow(
            Exception('Network error'),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthImportRequested('nsec1test')),
        expect: () => [
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticating,
          ),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Failed to import key'),
              ),
        ],
      );
    });

    group('AuthNip07Requested', () {
      blocTest<AuthBloc, AuthState>(
        'emits authenticating then authenticated on success',
        setUp: () {
          when(() => mockAuthRepository.loginWithNip07()).thenAnswer(
            (_) async => const AuthUser(
              publicKey: 'nip07pubkey',
              method: AuthMethod.nip07,
            ),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthNip07Requested()),
        expect: () => [
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticating,
          ),
          const AuthState(
            status: AuthStatus.authenticated,
            method: AuthMethod.nip07,
            publicKey: 'nip07pubkey',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits error with message on Nip07NotAvailableException',
        setUp: () {
          when(() => mockAuthRepository.loginWithNip07()).thenThrow(
            const Nip07NotAvailableException(),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthNip07Requested()),
        expect: () => [
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticating,
          ),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                'NIP-07 browser extension not installed',
              ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits generic error on other exceptions',
        setUp: () {
          when(() => mockAuthRepository.loginWithNip07()).thenThrow(
            Exception('Connection error'),
          );
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const AuthNip07Requested()),
        expect: () => [
          isA<AuthState>().having(
            (s) => s.status,
            'status',
            AuthStatus.authenticating,
          ),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Failed to connect with extension'),
              ),
        ],
      );
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits unauthenticated and calls repository logout',
        setUp: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
        },
        build: () => AuthBloc(authRepository: mockAuthRepository),
        seed: () => const AuthState(
          status: AuthStatus.authenticated,
          method: AuthMethod.guest,
          publicKey: 'pubkey',
        ),
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthState(status: AuthStatus.unauthenticated),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.logout()).called(1);
        },
      );
    });

    group('AuthErrorCleared', () {
      blocTest<AuthBloc, AuthState>(
        'emits unauthenticated from error state',
        build: () => AuthBloc(authRepository: mockAuthRepository),
        seed: () => const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Some error',
        ),
        act: (bloc) => bloc.add(const AuthErrorCleared()),
        expect: () => [
          const AuthState(status: AuthStatus.unauthenticated),
        ],
      );
    });
  });
}
