import 'package:auth_repository/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockRelayPool extends Mock implements RelayPool {}

class MockPixelRepository extends Mock implements PixelRepository {}

class FakeNostrSigner extends Fake implements NostrSigner {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockRelayPool mockRelayPool;
  late MockPixelRepository mockPixelRepository;
  late AuthRepository authRepository;

  setUpAll(() {
    registerFallbackValue(FakeNostrSigner());
  });

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockRelayPool = MockRelayPool();
    mockPixelRepository = MockPixelRepository();

    // Default storage stubs
    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});

    // Default RelayPool stubs
    when(() => mockRelayPool.isInitialized).thenReturn(false);
    when(
      () => mockRelayPool.initialize(
        signer: any(named: 'signer'),
        powDifficulty: any(named: 'powDifficulty'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockRelayPool.addRelay(any()),
    ).thenAnswer((_) async {});
    when(() => mockRelayPool.deinitialize()).thenAnswer((_) async {});

    // Default PixelRepository stubs
    when(() => mockPixelRepository.clear()).thenReturn(null);

    authRepository = AuthRepository(
      relayPool: mockRelayPool,
      pixelRepository: mockPixelRepository,
      initialRelayUrls: ['wss://test.relay'],
      powDifficulty: 0,
      storage: mockStorage,
    );
  });

  group('AuthRepository', () {
    group('checkStoredCredentials', () {
      test('returns null when no credentials stored', () async {
        when(
          () => mockStorage.read(key: 'auth_method'),
        ).thenAnswer((_) async => null);

        final result = await authRepository.checkStoredCredentials();

        expect(result, isNull);
      });

      test(
        'returns null and clears NIP-07 credentials when extension unavailable',
        () async {
          // NIP-07 sessions require the browser extension to be available.
          // In tests, Nip07Signer.isAvailable is false, so it clears creds.
          when(
            () => mockStorage.read(key: 'auth_method'),
          ).thenAnswer((_) async => 'nip07');
          when(
            () => mockStorage.read(key: 'auth_public_key'),
          ).thenAnswer((_) async => 'pubkey123');

          final result = await authRepository.checkStoredCredentials();

          expect(result, isNull);
          verify(() => mockStorage.delete(key: 'auth_method')).called(1);
          verify(() => mockStorage.delete(key: 'auth_public_key')).called(1);
          verify(() => mockStorage.delete(key: 'auth_private_key')).called(1);
        },
      );

      test('returns null when private key is missing', () async {
        when(
          () => mockStorage.read(key: 'auth_method'),
        ).thenAnswer((_) async => 'guest');
        when(
          () => mockStorage.read(key: 'auth_public_key'),
        ).thenAnswer((_) async => 'pubkey123');
        when(
          () => mockStorage.read(key: 'auth_private_key'),
        ).thenAnswer((_) async => null);

        final result = await authRepository.checkStoredCredentials();

        expect(result, isNull);
      });

      test('returns AuthUser when valid credentials exist', () async {
        // Valid 32-byte hex private key (64 characters)
        const privateKey =
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

        when(
          () => mockStorage.read(key: 'auth_method'),
        ).thenAnswer((_) async => 'guest');
        when(
          () => mockStorage.read(key: 'auth_public_key'),
        ).thenAnswer((_) async => 'pubkey123');
        when(
          () => mockStorage.read(key: 'auth_private_key'),
        ).thenAnswer((_) async => privateKey);

        final result = await authRepository.checkStoredCredentials();

        expect(result, isNotNull);
        expect(result!.method, AuthMethod.guest);
        verify(
          () => mockRelayPool.initialize(
            signer: any(named: 'signer'),
          ),
        ).called(1);
        verify(() => mockRelayPool.addRelay('wss://test.relay')).called(1);
      });
    });

    group('loginAsGuest', () {
      test('returns AuthUser with guest method', () async {
        final result = await authRepository.loginAsGuest();

        expect(result.method, AuthMethod.guest);
        expect(result.publicKey, isNotEmpty);
        verify(
          () => mockStorage.write(
            key: 'auth_method',
            value: 'guest',
          ),
        ).called(1);
        verify(
          () => mockRelayPool.initialize(
            signer: any(named: 'signer'),
          ),
        ).called(1);
        verify(() => mockRelayPool.addRelay('wss://test.relay')).called(1);
      });
    });

    group('loginWithNsec', () {
      test('throws InvalidNsecException for invalid prefix', () async {
        expect(
          () => authRepository.loginWithNsec('invalid_key'),
          throwsA(isA<InvalidNsecException>()),
        );
      });

      test('throws InvalidNsecException for malformed nsec', () async {
        expect(
          () => authRepository.loginWithNsec('nsec1invalid'),
          throwsA(isA<InvalidNsecException>()),
        );
      });
    });

    group('logout', () {
      test('clears repository, pool, and credentials', () async {
        await authRepository.logout();

        verify(() => mockPixelRepository.clear()).called(1);
        verify(() => mockRelayPool.deinitialize()).called(1);
        verify(() => mockStorage.delete(key: 'auth_method')).called(1);
        verify(() => mockStorage.delete(key: 'auth_public_key')).called(1);
        verify(() => mockStorage.delete(key: 'auth_private_key')).called(1);
      });
    });

    group('dispose', () {
      test('deinitializes RelayPool', () async {
        await authRepository.dispose();

        verify(() => mockRelayPool.deinitialize()).called(1);
      });
    });
  });
}
