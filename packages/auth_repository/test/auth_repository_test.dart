import 'package:auth_repository/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockNostrClient extends Mock implements NostrClient {}

class MockPixelRepository extends Mock implements PixelRepository {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockNostrClient mockNostrClient;
  late MockPixelRepository mockPixelRepository;
  late AuthRepository authRepository;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockNostrClient = MockNostrClient();
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

    // Default NostrClient stubs
    when(() => mockNostrClient.isInitialized).thenReturn(false);
    when(
      () => mockNostrClient.initialize(
        relayUrl: any(named: 'relayUrl'),
        signer: any(named: 'signer'),
        powDifficulty: any(named: 'powDifficulty'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockNostrClient.connect()).thenAnswer((_) async {});
    when(() => mockNostrClient.deinitialize()).thenAnswer((_) async {});

    // Default PixelRepository stubs
    when(() => mockPixelRepository.clear()).thenReturn(null);

    authRepository = AuthRepository(
      nostrClient: mockNostrClient,
      pixelRepository: mockPixelRepository,
      relayUrl: 'wss://test.relay',
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

      test('returns null and clears credentials for NIP-07 method', () async {
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
      });

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
          () => mockNostrClient.initialize(
            relayUrl: 'wss://test.relay',
            signer: any(named: 'signer'),
          ),
        ).called(1);
        verify(() => mockNostrClient.connect()).called(1);
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
          () => mockNostrClient.initialize(
            relayUrl: 'wss://test.relay',
            signer: any(named: 'signer'),
          ),
        ).called(1);
        verify(() => mockNostrClient.connect()).called(1);
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
      test('clears repository, client, and credentials', () async {
        await authRepository.logout();

        verify(() => mockPixelRepository.clear()).called(1);
        verify(() => mockNostrClient.deinitialize()).called(1);
        verify(() => mockStorage.delete(key: 'auth_method')).called(1);
        verify(() => mockStorage.delete(key: 'auth_public_key')).called(1);
        verify(() => mockStorage.delete(key: 'auth_private_key')).called(1);
      });
    });

    group('dispose', () {
      test('deinitializes NostrClient', () async {
        await authRepository.dispose();

        verify(() => mockNostrClient.deinitialize()).called(1);
      });
    });
  });
}
