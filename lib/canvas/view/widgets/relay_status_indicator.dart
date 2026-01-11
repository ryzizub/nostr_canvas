import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:nostr_place/relay/relay.dart';

class RelayStatusIndicator extends StatelessWidget {
  const RelayStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RelayBloc, RelayState>(
      builder: (context, state) {
        return Tooltip(
          message: _getTooltipMessage(state.connectionState),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIcon(state.connectionState),
              color: _getColor(state.connectionState),
              size: 24,
            ),
          ),
        );
      },
    );
  }

  IconData _getIcon(ConnectionState state) {
    return switch (state) {
      ConnectionState.connected => Icons.cloud_done,
      ConnectionState.connecting => Icons.cloud_sync,
      ConnectionState.reconnecting => Icons.cloud_sync,
      ConnectionState.disconnected => Icons.cloud_off,
      ConnectionState.error => Icons.cloud_off,
    };
  }

  Color _getColor(ConnectionState state) {
    return switch (state) {
      ConnectionState.connected => Colors.green,
      ConnectionState.connecting => Colors.orange,
      ConnectionState.reconnecting => Colors.orange,
      ConnectionState.disconnected => Colors.grey,
      ConnectionState.error => Colors.red,
    };
  }

  String _getTooltipMessage(ConnectionState state) {
    return switch (state) {
      ConnectionState.connected => 'Connected to relay',
      ConnectionState.connecting => 'Connecting...',
      ConnectionState.reconnecting => 'Reconnecting...',
      ConnectionState.disconnected => 'Disconnected',
      ConnectionState.error => 'Connection error',
    };
  }
}
