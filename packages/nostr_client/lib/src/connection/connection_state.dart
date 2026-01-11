/// Connection states for relay management.
enum ConnectionState {
  /// Not connected to any relay.
  disconnected,

  /// Currently connecting to relays.
  connecting,

  /// Connected to at least one relay.
  connected,

  /// Connection lost, attempting to reconnect.
  reconnecting,

  /// Connection error occurred.
  error,
}
