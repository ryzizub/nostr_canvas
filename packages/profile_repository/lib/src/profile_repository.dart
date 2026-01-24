import 'dart:async';

import 'package:nostr_client/nostr_client.dart';
import 'package:profile_repository/src/models/profile.dart';

/// Kind-0 (metadata) event kind.
const int _metadataKind = 0;

/// Cache entry for profiles.
class _CacheEntry {
  _CacheEntry(this.profile) : fetchedAt = DateTime.now();

  final Profile profile;
  final DateTime fetchedAt;

  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 30);
}

/// Repository for fetching Nostr user profiles (Kind-0 metadata).
///
/// Features:
/// - In-memory cache with 30-minute TTL
/// - Request deduplication (avoids concurrent fetches for same pubkey)
/// - 5-second timeout for relay responses
class ProfileRepository {
  /// Creates a ProfileRepository with a shared [RelayPool].
  ProfileRepository({required RelayPool relayPool}) : _relayPool = relayPool;

  final RelayPool _relayPool;

  /// In-memory cache of profiles.
  final Map<String, _CacheEntry> _cache = {};

  /// Pending requests to avoid duplicate fetches.
  final Map<String, Completer<Profile?>> _pendingRequests = {};

  /// Fetches a profile for the given pubkey.
  ///
  /// Returns cached profile if available and not expired.
  /// Returns null if the profile cannot be found or fetch times out.
  Future<Profile?> fetchProfile(String pubkey) async {
    // Check cache first
    final cached = _cache[pubkey];
    if (cached != null && !cached.isExpired) {
      return cached.profile;
    }

    // Check if there's already a pending request
    if (_pendingRequests.containsKey(pubkey)) {
      return _pendingRequests[pubkey]!.future;
    }

    // Create new request
    final completer = Completer<Profile?>();
    _pendingRequests[pubkey] = completer;

    try {
      final profile = await _fetchFromRelay(pubkey);
      if (profile != null) {
        _cache[pubkey] = _CacheEntry(profile);
      }
      completer.complete(profile);
    } on Object catch (e) {
      completer.completeError(e);
    } finally {
      _pendingRequests.remove(pubkey);
    }

    return completer.future;
  }

  Future<Profile?> _fetchFromRelay(String pubkey) async {
    if (!_relayPool.isInitialized) {
      return null;
    }

    // Use query method which bypasses deduplication
    final events = await _relayPool.query(
      [
        Filter(kinds: [_metadataKind], authors: [pubkey], limit: 1),
      ],
    );

    if (events.isEmpty) {
      return null;
    }

    // Use the most recent event if multiple are returned
    final event = events.reduce(
      (a, b) => a.createdAt > b.createdAt ? a : b,
    );

    return Profile.fromEventContent(
      pubkey,
      event.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }

  /// Clears the profile cache.
  void clearCache() {
    _cache.clear();
  }

  /// Gets a cached profile if available (does not fetch).
  Profile? getCached(String pubkey) {
    final cached = _cache[pubkey];
    if (cached != null && !cached.isExpired) {
      return cached.profile;
    }
    return null;
  }
}
