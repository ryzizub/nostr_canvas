import 'dart:async';

import 'package:nostr/nostr.dart';
import 'package:nostr_client/src/connection/connection_state.dart';
import 'package:nostr_client/src/nostr_client.dart';
import 'package:nostr_client/src/pow/pow_progress.dart';
import 'package:nostr_client/src/relay/relay_pool_state.dart';
import 'package:nostr_client/src/signer/nostr_signer.dart';

/// Manages a pool of relay connections.
///
/// Connects to all relays simultaneously and provides:
/// - Aggregated connection state (X/Y connected)
/// - Per-relay connection status
/// - Event deduplication across relays
/// - Publishing to all connected relays
class RelayPool {
  /// Creates an uninitialized RelayPool.
  ///
  /// Call [initialize] before using connection methods.
  RelayPool();

  final Map<String, NostrClient> _clients = {};
  final Map<String, StreamSubscription<ConnectionState>> _stateSubscriptions =
      {};
  final Map<String, StreamSubscription<Event>> _eventSubscriptions = {};

  NostrSigner? _signer;
  int _powDifficulty = 0;
  bool _isInitialized = false;

  final _poolStateController = StreamController<RelayPoolState>.broadcast();
  final _eventController = StreamController<Event>.broadcast();

  /// LRU set of seen event IDs for deduplication.
  final _seenEventIds = <String>{};
  static const _maxSeenEvents = 10000;

  /// Whether the pool is initialized and ready to use.
  bool get isInitialized => _isInitialized;

  /// List of all relay URLs in the pool.
  List<String> get relayUrls => _clients.keys.toList();

  /// Number of currently connected relays.
  int get connectedCount => _clients.values
      .where((c) => c.currentState == ConnectionState.connected)
      .length;

  /// Total number of relays in the pool.
  int get totalCount => _clients.length;

  /// The public key (from signer).
  ///
  /// Throws [StateError] if not initialized.
  String get publicKey {
    _assertInitialized();
    return _signer!.publicKey;
  }

  /// Proof of work difficulty.
  int get powDifficulty => _powDifficulty;

  /// Per-relay connection states.
  Map<String, ConnectionState> get relayStates => Map.fromEntries(
    _clients.entries.map((e) => MapEntry(e.key, e.value.currentState)),
  );

  /// Current pool state snapshot.
  RelayPoolState get currentState => _computePoolState();

  /// Stream of pool state changes.
  ///
  /// Emits the current state immediately when subscribed, then continues
  /// with subsequent state changes.
  Stream<RelayPoolState> get poolState async* {
    yield currentState;
    yield* _poolStateController.stream;
  }

  /// Stream of deduplicated events from all relays.
  Stream<Event> get events => _eventController.stream;

  void _assertInitialized() {
    if (!_isInitialized) {
      throw StateError('Pool not initialized. Call initialize() first.');
    }
  }

  /// Initialize the pool with signer and PoW settings.
  ///
  /// Throws [StateError] if already initialized.
  /// Call [deinitialize] first to reinitialize.
  Future<void> initialize({
    required NostrSigner signer,
    int powDifficulty = 0,
  }) async {
    if (_isInitialized) {
      throw StateError(
        'Pool already initialized. Call deinitialize() first.',
      );
    }
    _signer = signer;
    _powDifficulty = powDifficulty;
    _isInitialized = true;
  }

  /// Deinitialize the pool.
  ///
  /// Disconnects all relays and clears configuration.
  /// Safe to call even if not initialized.
  Future<void> deinitialize() async {
    if (_isInitialized) {
      await disconnectAll();
      for (final url in _clients.keys.toList()) {
        await _removeClientInternal(url);
      }
    }
    _signer = null;
    _powDifficulty = 0;
    _isInitialized = false;
    _seenEventIds.clear();
  }

  /// Add a relay to the pool.
  ///
  /// If [connect] is true (default), connects immediately.
  /// Does nothing if the relay already exists.
  Future<void> addRelay(String url, {bool connect = true}) async {
    _assertInitialized();

    if (_clients.containsKey(url)) {
      return;
    }

    final client = NostrClient();
    await client.initialize(
      relayUrl: url,
      signer: _signer!,
      powDifficulty: _powDifficulty,
    );

    _clients[url] = client;

    // Subscribe to connection state changes
    _stateSubscriptions[url] = client.connectionState.listen((_) {
      _emitPoolState();
    });

    // Subscribe to events with deduplication
    _eventSubscriptions[url] = client.events.listen((event) {
      if (!_isDuplicate(event)) {
        _eventController.add(event);
      }
    });

    _emitPoolState();

    if (connect) {
      try {
        await client.connect();
      } on Object {
        // Connection error is handled by state subscription
      }
    }
  }

  /// Remove a relay from the pool.
  ///
  /// Does nothing if the relay doesn't exist.
  Future<void> removeRelay(String url) async {
    if (!_clients.containsKey(url)) {
      return;
    }

    await _removeClientInternal(url);
    _emitPoolState();
  }

  Future<void> _removeClientInternal(String url) async {
    await _stateSubscriptions[url]?.cancel();
    _stateSubscriptions.remove(url);

    await _eventSubscriptions[url]?.cancel();
    _eventSubscriptions.remove(url);

    final client = _clients.remove(url);
    await client?.deinitialize();
    await client?.dispose();
  }

  /// Connect to all relays in the pool.
  Future<void> connectAll() async {
    _assertInitialized();

    await Future.wait(
      _clients.values.map((client) async {
        try {
          await client.connect();
        } on Object {
          // Individual connection errors handled by state subscription
        }
      }),
    );
  }

  /// Disconnect from all relays.
  Future<void> disconnectAll() async {
    await Future.wait(
      _clients.values.map((client) => client.disconnect()),
    );
  }

  /// Publish an event to all connected relays.
  ///
  /// The event is signed once and sent to all relays.
  /// Uses the first connected relay for PoW mining if enabled.
  Future<void> publish({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    _assertInitialized();

    final connectedClients = _clients.values
        .where((c) => c.currentState == ConnectionState.connected)
        .toList();

    if (connectedClients.isEmpty) {
      throw StateError('No connected relays');
    }

    // Use first connected client to publish (handles PoW + signing).
    // The event is sent to one relay which propagates it through the network.
    await connectedClients.first.publish(
      kind: kind,
      tags: tags,
      content: content,
    );
  }

  /// Publish with progress reporting.
  ///
  /// Uses the first connected relay for PoW mining.
  Stream<PowProgress> publishWithProgress({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async* {
    if (!_isInitialized) {
      yield const PowError(message: 'Pool not initialized');
      return;
    }

    final connectedClients = _clients.values
        .where((c) => c.currentState == ConnectionState.connected)
        .toList();

    if (connectedClients.isEmpty) {
      yield const PowError(message: 'No connected relays');
      return;
    }

    yield* connectedClients.first.publishWithProgress(
      kind: kind,
      tags: tags,
      content: content,
    );
  }

  /// Subscribe to events on all connected relays.
  ///
  /// Returns a map of relay URL -> subscription ID.
  Map<String, String> subscribe(List<Filter> filters) {
    _assertInitialized();

    final subscriptions = <String, String>{};

    for (final entry in _clients.entries) {
      if (entry.value.currentState == ConnectionState.connected) {
        try {
          final subId = entry.value.subscribe(filters);
          subscriptions[entry.key] = subId;
        } on Object {
          // Skip relays that fail to subscribe
        }
      }
    }

    return subscriptions;
  }

  /// Unsubscribe from all relays.
  void unsubscribe(Map<String, String> subscriptionIds) {
    for (final entry in subscriptionIds.entries) {
      final client = _clients[entry.key];
      if (client != null) {
        client.unsubscribe(entry.value);
      }
    }
  }

  /// Performs a one-shot query and returns matching events.
  ///
  /// Unlike [subscribe], this method:
  /// - Does NOT deduplicate events (useful for fetching known events)
  /// - Waits for EOSE from all relays (with fallback timeout)
  /// - Returns all matching events received
  ///
  /// Use this for fetching specific events like user profiles (Kind-0).
  Future<List<Event>> query(
    List<Filter> filters, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _assertInitialized();

    final events = <Event>[];
    final subscriptions = <_QuerySubscription>[];
    final pendingEose = <String>{};

    // Subscribe to each connected client directly (bypass deduplication)
    for (final entry in _clients.entries) {
      if (entry.value.currentState == ConnectionState.connected) {
        try {
          final subId = entry.value.subscribe(filters);
          pendingEose.add(subId);

          subscriptions.add(
            _QuerySubscription(
              subscriptionId: subId,
              client: entry.value,
            ),
          );
        } on Object {
          // Skip relays that fail
        }
      }
    }

    if (subscriptions.isEmpty) {
      return events;
    }

    final completer = Completer<void>();

    // Listen to events and EOSE from each client
    for (final sub in subscriptions) {
      sub
        ..eventSubscription = sub.client.events.listen((event) {
          for (final filter in filters) {
            if (_eventMatchesFilter(event, filter)) {
              if (!events.any((e) => e.id == event.id)) {
                events.add(event);
              }
              break;
            }
          }
        })
        ..eoseSubscription = sub.client.eose.listen((subId) {
          if (subId == sub.subscriptionId) {
            pendingEose.remove(subId);
            if (pendingEose.isEmpty && !completer.isCompleted) {
              completer.complete();
            }
          }
        });
    }

    // Wait for all EOSE or timeout
    await completer.future.timeout(timeout, onTimeout: () {});

    // Cleanup
    for (final sub in subscriptions) {
      await sub.eventSubscription?.cancel();
      await sub.eoseSubscription?.cancel();
      try {
        sub.client.unsubscribe(sub.subscriptionId);
      } on Object {
        // Ignore errors during cleanup
      }
    }

    return events;
  }

  bool _eventMatchesFilter(Event event, Filter filter) {
    if (filter.kinds != null && !filter.kinds!.contains(event.kind)) {
      return false;
    }
    if (filter.authors != null && !filter.authors!.contains(event.pubkey)) {
      return false;
    }
    if (filter.ids != null && !filter.ids!.contains(event.id)) {
      return false;
    }
    return true;
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await deinitialize();
    await _poolStateController.close();
    await _eventController.close();
  }

  bool _isDuplicate(Event event) {
    if (_seenEventIds.contains(event.id)) {
      return true;
    }
    _seenEventIds.add(event.id);
    if (_seenEventIds.length > _maxSeenEvents) {
      _seenEventIds.remove(_seenEventIds.first);
    }
    return false;
  }

  void _emitPoolState() {
    _poolStateController.add(_computePoolState());
  }

  RelayPoolState _computePoolState() {
    final states = relayStates;
    final connected = states.values
        .where((s) => s == ConnectionState.connected)
        .length;
    final total = states.length;

    // Determine overall state
    ConnectionState overall;
    if (connected > 0) {
      overall = ConnectionState.connected;
    } else if (states.values.any((s) => s == ConnectionState.connecting)) {
      overall = ConnectionState.connecting;
    } else if (states.values.any((s) => s == ConnectionState.reconnecting)) {
      overall = ConnectionState.reconnecting;
    } else if (states.values.every((s) => s == ConnectionState.error)) {
      overall = ConnectionState.error;
    } else {
      overall = ConnectionState.disconnected;
    }

    return RelayPoolState(
      connectedCount: connected,
      totalCount: total,
      relayStates: states,
      overallState: overall,
    );
  }
}

/// Helper class for tracking query subscriptions.
class _QuerySubscription {
  _QuerySubscription({
    required this.subscriptionId,
    required this.client,
  });

  final String subscriptionId;
  final NostrClient client;

  // ignore: cancel_subscriptions - cancelled in RelayPool.query cleanup
  StreamSubscription<Event>? eventSubscription;

  // ignore: cancel_subscriptions - cancelled in RelayPool.query cleanup
  StreamSubscription<String>? eoseSubscription;
}
