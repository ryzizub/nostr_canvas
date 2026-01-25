import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Nostr user profile from Kind-0 metadata event.
class Profile extends Equatable {
  /// Creates a Profile.
  const Profile({
    required this.pubkey,
    this.name,
    this.displayName,
    this.picture,
    this.about,
    this.nip05,
    this.createdAt,
  });

  /// Creates a Profile from Kind-0 event content JSON.
  factory Profile.fromEventContent(
    String pubkey,
    String content, {
    DateTime? createdAt,
  }) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Profile(
        pubkey: pubkey,
        name: json['name'] as String?,
        displayName: json['display_name'] as String?,
        picture: json['picture'] as String?,
        about: json['about'] as String?,
        nip05: json['nip05'] as String?,
        createdAt: createdAt,
      );
    } on Object {
      return Profile(pubkey: pubkey, createdAt: createdAt);
    }
  }

  /// The hex-encoded public key.
  final String pubkey;

  /// The username (name field).
  final String? name;

  /// The display name.
  final String? displayName;

  /// Profile picture URL.
  final String? picture;

  /// About/bio text.
  final String? about;

  /// NIP-05 identifier.
  final String? nip05;

  /// When the profile was created/updated.
  final DateTime? createdAt;

  /// Returns the best available name for display.
  ///
  /// Prefers displayName, falls back to name, then truncated pubkey.
  String get bestName => displayName ?? name ?? '${pubkey.substring(0, 8)}...';

  /// Whether this profile has any metadata.
  bool get hasMetadata =>
      name != null ||
      displayName != null ||
      picture != null ||
      about != null ||
      nip05 != null;

  @override
  List<Object?> get props => [
    pubkey,
    name,
    displayName,
    picture,
    about,
    nip05,
    createdAt,
  ];
}
