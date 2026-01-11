import 'dart:async' show StreamController, StreamSubscription, unawaited;
import 'dart:convert';
import 'dart:isolate';

import 'package:nostr/nostr.dart';
import 'package:nostr_client/src/connection/connection_state.dart';
import 'package:nostr_client/src/pow/pow_progress.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Web platform detection (compile-time constant).
const bool _isWeb = identical(0, 0.0);

/// Count leading zero bits in a hex string (NIP-13).
int _countLeadingZeroBits(String hex) {
  var count = 0;
  for (var i = 0; i < hex.length; i++) {
    final nibble = int.parse(hex[i], radix: 16);
    if (nibble == 0) {
      count += 4;
    } else {
      // Count leading zeros in this nibble
      if (nibble < 8) count += 1;
      if (nibble < 4) count += 1;
      if (nibble < 2) count += 1;
      break;
    }
  }
  return count;
}

/// Mine proof of work for an event (NIP-13).
///
/// Top-level function required for Isolate.run().
_PowResult _mineProofOfWork(_PowParams params) {
  final createdAt = currentUnixTimestampSeconds();
  var nonce = 0;

  while (true) {
    final testTags = [
      ...params.tags,
      ['nonce', nonce.toString(), params.targetDifficulty.toString()],
    ];

    final event = Event.partial(
      pubkey: params.pubkey,
      createdAt: createdAt,
      kind: params.kind,
      tags: testTags,
      content: params.content,
    );
    final eventId = event.getEventId();

    final difficulty = _countLeadingZeroBits(eventId);
    if (difficulty >= params.targetDifficulty) {
      return _PowResult(
        nonce: nonce.toString(),
        difficulty: difficulty,
        createdAt: createdAt,
      );
    }

    nonce++;
  }
}

/// Message types for isolate communication.
sealed class _IsolateMessage {}

class _IsolateProgress extends _IsolateMessage {
  _IsolateProgress(this.noncesAttempted, this.currentDifficulty);
  final int noncesAttempted;
  final int currentDifficulty;
}

class _IsolateComplete extends _IsolateMessage {
  _IsolateComplete(this.result);
  final _PowResult result;
}

/// Parameters for isolate mining with progress reporting.
class _PowIsolateParams {
  _PowIsolateParams({
    required this.sendPort,
    required this.pubkey,
    required this.kind,
    required this.tags,
    required this.content,
    required this.targetDifficulty,
  });

  final SendPort sendPort;
  final String pubkey;
  final int kind;
  final List<List<String>> tags;
  final String content;
  final int targetDifficulty;
}

/// Mine proof of work with progress reporting (for isolate).
///
/// Top-level function that sends progress updates via SendPort.
void _mineProofOfWorkWithProgress(_PowIsolateParams params) {
  final sendPort = params.sendPort;
  final createdAt = currentUnixTimestampSeconds();
  var nonce = 0;
  var bestDifficulty = 0;
  var lastReportNonce = 0;
  const reportInterval = 10000;

  while (true) {
    final testTags = [
      ...params.tags,
      ['nonce', nonce.toString(), params.targetDifficulty.toString()],
    ];

    final event = Event.partial(
      pubkey: params.pubkey,
      createdAt: createdAt,
      kind: params.kind,
      tags: testTags,
      content: params.content,
    );
    final eventId = event.getEventId();
    final difficulty = _countLeadingZeroBits(eventId);

    if (difficulty > bestDifficulty) {
      bestDifficulty = difficulty;
    }

    // Report progress every reportInterval nonces
    if (nonce - lastReportNonce >= reportInterval) {
      sendPort.send(_IsolateProgress(nonce, bestDifficulty));
      lastReportNonce = nonce;
    }

    if (difficulty >= params.targetDifficulty) {
      sendPort.send(
        _IsolateComplete(
          _PowResult(
            nonce: nonce.toString(),
            difficulty: difficulty,
            createdAt: createdAt,
          ),
        ),
      );
      return;
    }

    nonce++;
  }
}

/// Nostr client for relay communication.
///
/// Handles WebSocket connections to relays, event publishing,
/// and event subscriptions.
class NostrClient {
  /// Creates a NostrClient with the given relay URL and keychain.
  NostrClient({
    required this.relayUrl,
    required this.keychain,
    this.powDifficulty = 0,
  });

  /// The relay WebSocket URL.
  final String relayUrl;

  /// The keychain for signing events.
  final Keychain keychain;

  /// Proof of work difficulty (0 = disabled).
  final int powDifficulty;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  ConnectionState _currentState = ConnectionState.disconnected;

  final _eventController = StreamController<Event>.broadcast();

  /// Stream of connection state changes.
  Stream<ConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Current connection state.
  ConnectionState get currentState => _currentState;

  /// Stream of incoming events from the relay.
  Stream<Event> get events => _eventController.stream;

  /// The public key for this client.
  String get publicKey => keychain.public;

  void _updateState(ConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  /// Connect to the relay.
  Future<void> connect() async {
    if (_currentState == ConnectionState.connected ||
        _currentState == ConnectionState.connecting) {
      return;
    }

    _updateState(ConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(relayUrl));
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (Object error) {
          _updateState(ConnectionState.error);
        },
        onDone: () {
          if (_currentState != ConnectionState.disconnected) {
            _updateState(ConnectionState.reconnecting);
            _scheduleReconnect();
          }
        },
      );

      _updateState(ConnectionState.connected);
    } on Object {
      _updateState(ConnectionState.error);
      rethrow;
    }
  }

  void _scheduleReconnect() {
    unawaited(
      Future<void>.delayed(const Duration(seconds: 5), () async {
        if (_currentState == ConnectionState.reconnecting) {
          await connect();
        }
      }),
    );
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as List<dynamic>;
      final messageType = data[0] as String;

      if (messageType == 'EVENT' && data.length >= 3) {
        final event = Event.deserialize(data, verify: false);
        _eventController.add(event);
      }
    } on Object {
      // Skip malformed messages
    }
  }

  /// Disconnect from the relay.
  Future<void> disconnect() async {
    _updateState(ConnectionState.disconnected);
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  /// Publish an event to the relay.
  ///
  /// Creates and signs an event with the given kind, tags, and content.
  /// If [powDifficulty] > 0, mines proof of work before publishing.
  /// On native platforms, PoW runs in a separate isolate to avoid UI jank.
  Future<void> publish({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    if (_currentState != ConnectionState.connected || _channel == null) {
      throw StateError('Not connected to relay');
    }

    final eventTags = List<List<String>>.from(tags);

    // Mine PoW if difficulty is set
    int? createdAt;
    if (powDifficulty > 0) {
      final params = _PowParams(
        pubkey: keychain.public,
        kind: kind,
        tags: eventTags,
        content: content,
        targetDifficulty: powDifficulty,
      );

      _PowResult powResult;
      if (_isWeb) {
        // Web: run synchronously (isolates not supported)
        powResult = _mineProofOfWork(params);
      } else {
        // Native: run in isolate to avoid blocking UI
        powResult = await Isolate.run(() => _mineProofOfWork(params));
      }

      eventTags.add([
        'nonce',
        powResult.nonce,
        powDifficulty.toString(), // Must match target used during mining
      ]);
      createdAt = powResult.createdAt;
    }

    final event = Event.from(
      kind: kind,
      tags: eventTags,
      content: content,
      privkey: keychain.private,
      createdAt: createdAt,
    );

    final message = jsonEncode(['EVENT', event.toJson()]);
    _channel!.sink.add(message);
  }

  /// Publish an event with progress reporting.
  ///
  /// Returns a stream of [PowProgress] updates during mining and sending.
  /// If [powDifficulty] > 0, emits mining progress before sending.
  Stream<PowProgress> publishWithProgress({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async* {
    if (_currentState != ConnectionState.connected || _channel == null) {
      yield const PowError(message: 'Not connected to relay');
      return;
    }

    final eventTags = List<List<String>>.from(tags);
    int? createdAt;
    _PowResult? powResult;

    if (powDifficulty > 0) {
      final params = _PowParams(
        pubkey: keychain.public,
        kind: kind,
        tags: eventTags,
        content: content,
        targetDifficulty: powDifficulty,
      );

      if (_isWeb) {
        // Web: use async generator with chunked execution
        await for (final progress in _mineProofOfWorkWeb(params)) {
          yield progress;
          if (progress is PowComplete) {
            powResult = _PowResult(
              nonce: progress.nonce,
              difficulty: progress.achievedDifficulty,
              createdAt: progress.createdAt,
            );
          }
        }
      } else {
        // Native: use isolate with ports
        await for (final progress in _mineProofOfWorkNative(params)) {
          yield progress;
          if (progress is PowComplete) {
            powResult = _PowResult(
              nonce: progress.nonce,
              difficulty: progress.achievedDifficulty,
              createdAt: progress.createdAt,
            );
          }
        }
      }

      if (powResult == null) {
        yield const PowError(message: 'Mining failed');
        return;
      }

      eventTags.add([
        'nonce',
        powResult.nonce,
        powDifficulty.toString(),
      ]);
      createdAt = powResult.createdAt;
    }

    // Signal sending phase
    yield const PowSending();

    try {
      final event = Event.from(
        kind: kind,
        tags: eventTags,
        content: content,
        privkey: keychain.private,
        createdAt: createdAt,
      );

      final message = jsonEncode(['EVENT', event.toJson()]);
      _channel!.sink.add(message);

      yield PowSuccess(eventId: event.id);
    } on Object catch (e) {
      yield PowError(message: e.toString());
    }
  }

  /// Web implementation of PoW mining with progress.
  Stream<PowProgress> _mineProofOfWorkWeb(_PowParams params) async* {
    final createdAt = currentUnixTimestampSeconds();
    final startTime = DateTime.now().millisecondsSinceEpoch;
    var nonce = 0;
    var bestDifficulty = 0;
    const chunkSize = 1000;

    while (true) {
      // Process a chunk of nonces
      for (var i = 0; i < chunkSize; i++) {
        final testTags = [
          ...params.tags,
          ['nonce', nonce.toString(), params.targetDifficulty.toString()],
        ];

        final event = Event.partial(
          pubkey: params.pubkey,
          createdAt: createdAt,
          kind: params.kind,
          tags: testTags,
          content: params.content,
        );
        final eventId = event.getEventId();
        final difficulty = _countLeadingZeroBits(eventId);

        if (difficulty > bestDifficulty) {
          bestDifficulty = difficulty;
        }

        if (difficulty >= params.targetDifficulty) {
          final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
          yield PowComplete(
            nonce: nonce.toString(),
            achievedDifficulty: difficulty,
            targetDifficulty: params.targetDifficulty,
            elapsedMilliseconds: elapsed,
            createdAt: createdAt,
          );
          return;
        }

        nonce++;
      }

      // Yield progress and allow UI to update
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      yield PowMining(
        noncesAttempted: nonce,
        currentDifficulty: bestDifficulty,
        targetDifficulty: params.targetDifficulty,
        elapsedMilliseconds: elapsed,
      );

      // Yield to event loop for UI responsiveness
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Native implementation of PoW mining with progress using isolate.
  Stream<PowProgress> _mineProofOfWorkNative(_PowParams params) async* {
    final receivePort = ReceivePort();
    final startTime = DateTime.now().millisecondsSinceEpoch;

    final isolateParams = _PowIsolateParams(
      sendPort: receivePort.sendPort,
      pubkey: params.pubkey,
      kind: params.kind,
      tags: params.tags,
      content: params.content,
      targetDifficulty: params.targetDifficulty,
    );

    await Isolate.spawn(_mineProofOfWorkWithProgress, isolateParams);

    await for (final message in receivePort) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;

      if (message is _IsolateProgress) {
        yield PowMining(
          noncesAttempted: message.noncesAttempted,
          currentDifficulty: message.currentDifficulty,
          targetDifficulty: params.targetDifficulty,
          elapsedMilliseconds: elapsed,
        );
      } else if (message is _IsolateComplete) {
        yield PowComplete(
          nonce: message.result.nonce,
          achievedDifficulty: message.result.difficulty,
          targetDifficulty: params.targetDifficulty,
          elapsedMilliseconds: elapsed,
          createdAt: message.result.createdAt,
        );
        receivePort.close();
        return;
      }
    }
  }

  /// Subscribe to events matching the given filters.
  ///
  /// Returns a subscription ID that can be used to unsubscribe.
  String subscribe(List<Filter> filters) {
    if (_currentState != ConnectionState.connected || _channel == null) {
      throw StateError('Not connected to relay');
    }

    final subscriptionId = generate64RandomHexChars().substring(0, 16);
    final filtersJson = filters.map((f) => f.toJson()).toList();
    final message = jsonEncode(['REQ', subscriptionId, ...filtersJson]);
    _channel!.sink.add(message);

    return subscriptionId;
  }

  /// Unsubscribe from a subscription.
  void unsubscribe(String subscriptionId) {
    if (_currentState != ConnectionState.connected || _channel == null) {
      return;
    }

    final message = jsonEncode(['CLOSE', subscriptionId]);
    _channel!.sink.add(message);
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _eventController.close();
  }
}

/// Parameters for PoW mining function.
class _PowParams {
  _PowParams({
    required this.pubkey,
    required this.kind,
    required this.tags,
    required this.content,
    required this.targetDifficulty,
  });

  final String pubkey;
  final int kind;
  final List<List<String>> tags;
  final String content;
  final int targetDifficulty;
}

class _PowResult {
  _PowResult({
    required this.nonce,
    required this.difficulty,
    required this.createdAt,
  });
  final String nonce;
  final int difficulty;
  final int createdAt;
}
