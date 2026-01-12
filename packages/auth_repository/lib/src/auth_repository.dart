import 'package:auth_repository/src/models/auth_method.dart';
import 'package:auth_repository/src/models/auth_user.dart';
import 'package:auth_repository/src/models/stored_credentials.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nostr/nostr.dart' show Nip19;
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Authentication repository for Nostr Canvas.
///
/// Handles credential storage, NostrClient lifecycle, and authentication.
/// This is a pure data layer - no state management.
class AuthRepository {
  AuthRepository({
    required NostrClient nostrClient,
    required PixelRepository pixelRepository,
    required String relayUrl,
    required int powDifficulty,
    FlutterSecureStorage? storage,
  }) : _nostrClient = nostrClient,
       _pixelRepository = pixelRepository,
       _relayUrl = relayUrl,
       _powDifficulty = powDifficulty,
       _storage =
           storage ??
           const FlutterSecureStorage(
             webOptions: WebOptions(
               dbName: 'nostr_canvas_auth',
               publicKey: 'nostr_canvas_auth_key',
             ),
           );

  final NostrClient _nostrClient;
  final PixelRepository _pixelRepository;
  final String _relayUrl;
  final int _powDifficulty;
  final FlutterSecureStorage _storage;

  static const _keyMethod = 'auth_method';
  static const _keyPublicKey = 'auth_public_key';
  static const _keyPrivateKey = 'auth_private_key';

  NostrSigner? _signer;

  /// The current NostrSigner (null if not authenticated).
  NostrSigner? get signer => _signer;

  /// The Nostr client.
  NostrClient get nostrClient => _nostrClient;

  /// Check for stored credentials and restore session.
  ///
  /// Returns [AuthUser] if session can be restored, null otherwise.
  /// Throws on connection failure.
  Future<AuthUser?> checkStoredCredentials() async {
    final credentials = await _getCredentials();

    if (credentials == null) {
      return null;
    }

    // Don't restore NIP-07 sessions (requires re-auth with extension)
    if (credentials.method == AuthMethod.nip07.name) {
      await _clearCredentials();
      return null;
    }

    // Need private key to restore session
    if (credentials.privateKey == null) {
      return null;
    }

    _signer = LocalSigner.fromPrivateKeyHex(credentials.privateKey!);
    await _connectClient();

    final method = AuthMethod.values.firstWhere(
      (m) => m.name == credentials.method,
      orElse: () => AuthMethod.guest,
    );

    return AuthUser(
      publicKey: credentials.publicKey,
      method: method,
    );
  }

  /// Login as guest (generate new random key).
  ///
  /// Returns [AuthUser] on success, throws on failure.
  Future<AuthUser> loginAsGuest() async {
    final localSigner = LocalSigner.generate();
    _signer = localSigner;

    await _saveCredentials(
      method: AuthMethod.guest.name,
      publicKey: localSigner.publicKey,
      privateKey: localSigner.privateKey,
    );

    await _connectClient();

    return AuthUser(
      publicKey: localSigner.publicKey,
      method: AuthMethod.guest,
    );
  }

  /// Login with nsec key.
  ///
  /// Returns [AuthUser] on success.
  /// Throws [InvalidNsecException] on invalid key format.
  Future<AuthUser> loginWithNsec(String nsec) async {
    final privateKeyHex = _parseNsec(nsec);
    final localSigner = LocalSigner.fromPrivateKeyHex(privateKeyHex);
    _signer = localSigner;

    await _saveCredentials(
      method: AuthMethod.imported.name,
      publicKey: localSigner.publicKey,
      privateKey: localSigner.privateKey,
    );

    await _connectClient();

    return AuthUser(
      publicKey: localSigner.publicKey,
      method: AuthMethod.imported,
    );
  }

  /// Login with NIP-07 browser extension.
  ///
  /// Returns [AuthUser] on success.
  /// Throws [SignerException] if extension not available.
  Future<AuthUser> loginWithNip07() async {
    final nip07Signer = await Nip07Signer.create();
    _signer = nip07Signer;

    await _saveCredentials(
      method: AuthMethod.nip07.name,
      publicKey: nip07Signer.publicKey,
    );

    await _connectClient();

    return AuthUser(
      publicKey: nip07Signer.publicKey,
      method: AuthMethod.nip07,
    );
  }

  /// Logout and disconnect.
  Future<void> logout() async {
    // Clear pixel repository data
    _pixelRepository.clear();

    // Deinitialize NostrClient (disconnect and clear config)
    await _nostrClient.deinitialize();
    _signer = null;

    // Clear stored credentials
    await _clearCredentials();
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _nostrClient.deinitialize();
  }

  // Private helpers

  Future<void> _connectClient() async {
    if (_signer == null) return;

    await _nostrClient.initialize(
      relayUrl: _relayUrl,
      signer: _signer!,
      powDifficulty: _powDifficulty,
    );
    await _nostrClient.connect();
  }

  String _parseNsec(String nsec) {
    final trimmed = nsec.trim();

    if (!trimmed.startsWith('nsec1')) {
      throw const InvalidNsecException('Key must start with nsec1');
    }

    try {
      return Nip19.decodePrivkey(trimmed);
    } on FormatException catch (e) {
      throw InvalidNsecException('Invalid nsec: ${e.message}');
    } on Object {
      throw const InvalidNsecException('Invalid nsec format');
    }
  }

  // Secure storage helpers

  Future<void> _saveCredentials({
    required String method,
    required String publicKey,
    String? privateKey,
  }) async {
    await _storage.write(key: _keyMethod, value: method);
    await _storage.write(key: _keyPublicKey, value: publicKey);
    if (privateKey != null) {
      await _storage.write(key: _keyPrivateKey, value: privateKey);
    } else {
      await _storage.delete(key: _keyPrivateKey);
    }
  }

  Future<StoredCredentials?> _getCredentials() async {
    final method = await _storage.read(key: _keyMethod);
    final publicKey = await _storage.read(key: _keyPublicKey);
    final privateKey = await _storage.read(key: _keyPrivateKey);

    if (method == null || publicKey == null) {
      return null;
    }

    return StoredCredentials(
      method: method,
      publicKey: publicKey,
      privateKey: privateKey,
    );
  }

  Future<void> _clearCredentials() async {
    await _storage.delete(key: _keyMethod);
    await _storage.delete(key: _keyPublicKey);
    await _storage.delete(key: _keyPrivateKey);
  }
}
