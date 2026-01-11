import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
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
          preferBelow: false,
          child: NesContainer(
            padding: const EdgeInsets.all(8),
            child: NesIcon(
              iconData: _getIconData(state.connectionState),
              primaryColor: _getColor(state.connectionState),
            ),
          ),
        );
      },
    );
  }

  NesIconData _getIconData(ConnectionState state) {
    return switch (state) {
      ConnectionState.connected => NesIcons.check,
      ConnectionState.connecting => NesIcons.radio,
      ConnectionState.reconnecting => NesIcons.radio,
      ConnectionState.disconnected => NesIcons.close,
      ConnectionState.error => NesIcons.exclamationMarkBlock,
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
