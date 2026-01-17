import 'package:auth_repository/src/models/auth_method.dart';
import 'package:auth_repository/src/models/auth_user.dart';
import 'package:auth_repository/src/models/stored_credentials.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nostr/nostr.dart' show Nip19;
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Authentication repository for Nostr Canvas.
///
/// Handles credential storage, RelayPool lifecycle, and authentication.
/// This is a pure data layer - no state management.
class AuthRepository {
  AuthRepository({
    required RelayPool relayPool,
    required PixelRepository pixelRepository,
    required List<String> initialRelayUrls,
    required int powDifficulty,
    FlutterSecureStorage? storage,
  }) : _relayPool = relayPool,
       _pixelRepository = pixelRepository,
       _initialRelayUrls = initialRelayUrls,
       _powDifficulty = powDifficulty,
       _storage =
           storage ??
           const FlutterSecureStorage(
             webOptions: WebOptions(
               dbName: 'nostr_canvas_auth',
               publicKey: 'nostr_canvas_auth_key',
             ),
           );

  final RelayPool _relayPool;
  final PixelRepository _pixelRepository;
  final List<String> _initialRelayUrls;
  final int _powDifficulty;
  final FlutterSecureStorage _storage;

  static const _keyMethod = 'auth_method';
  static const _keyPublicKey = 'auth_public_key';
  static const _keyPrivateKey = 'auth_private_key';

  NostrSigner? _signer;

  /// The current NostrSigner (null if not authenticated).
  NostrSigner? get signer => _signer;

  /// The relay pool.
  RelayPool get relayPool => _relayPool;

  /// Check for stored credentials and restore session.
  ///
  /// Returns [AuthUser] if session can be restored, null otherwise.
  /// Throws on connection failure.
  Future<AuthUser?> checkStoredCredentials() async {
    final credentials = await _getCredentials();

    if (credentials == null) {
      return null;
    }

    // Try to restore NIP-07 session automatically
    if (credentials.method == AuthMethod.nip07.name) {
      return _tryRestoreNip07Session(credentials.publicKey);
    }

    // Need private key to restore session
    if (credentials.privateKey == null) {
      return null;
    }

    _signer = LocalSigner.fromPrivateKeyHex(credentials.privateKey!);
    await _connectPool();

    final method = AuthMethod.values.firstWhere(
      (m) => m.name == credentials.method,
      orElse: () => AuthMethod.guest,
    );

    return AuthUser(
      publicKey: credentials.publicKey,
      method: method,
    );
  }

  /// Try to restore a NIP-07 session by re-authenticating with the extension.
  ///
  /// Returns [AuthUser] if extension is available and user approves,
  /// null otherwise (clears credentials on failure).
  Future<AuthUser?> _tryRestoreNip07Session(String storedPublicKey) async {
    try {
      // Check if NIP-07 extension is available
      if (!Nip07Signer.isAvailable) {
        await _clearCredentials();
        return null;
      }

      // Try to get public key from extension (this may prompt user)
      final nip07Signer = await Nip07Signer.create();

      // Verify the public key matches the stored one
      if (nip07Signer.publicKey != storedPublicKey) {
        // Different account - clear stored credentials
        await _clearCredentials();
        return null;
      }

      _signer = nip07Signer;
      await _connectPool();

      return AuthUser(
        publicKey: nip07Signer.publicKey,
        method: AuthMethod.nip07,
      );
    } on SignerException {
      // Extension not available or user denied - clear credentials
      await _clearCredentials();
      return null;
    } on Object {
      // Any other error - clear credentials
      await _clearCredentials();
      return null;
    }
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

    await _connectPool();

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

    await _connectPool();

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

    await _connectPool();

    return AuthUser(
      publicKey: nip07Signer.publicKey,
      method: AuthMethod.nip07,
    );
  }

  /// Logout and disconnect.
  Future<void> logout() async {
    // Clear pixel repository data
    _pixelRepository.clear();

    // Deinitialize RelayPool (disconnect and clear config)
    await _relayPool.deinitialize();
    _signer = null;

    // Clear stored credentials
    await _clearCredentials();
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _relayPool.deinitialize();
  }

  // Private helpers

  Future<void> _connectPool() async {
    if (_signer == null) return;

    // Initialize the pool with signer and PoW settings
    await _relayPool.initialize(
      signer: _signer!,
      powDifficulty: _powDifficulty,
    );

    // Add all initial relays
    for (final url in _initialRelayUrls) {
      await _relayPool.addRelay(url);
    }
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
