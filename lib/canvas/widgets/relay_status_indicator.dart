import 'dart:async' show unawaited;

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/canvas/bloc/relay_bloc.dart';
import 'package:nostr_canvas/canvas/widgets/relay_list_dialog.dart';
import 'package:nostr_client/nostr_client.dart';

class RelayStatusIndicator extends StatelessWidget {
  const RelayStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RelayBloc, RelayState>(
      builder: (context, state) {
        return Tooltip(
          message: _getTooltipMessage(state),
          preferBelow: false,
          child: GestureDetector(
            onTap: () => _showRelayDialog(context),
            child: NesContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NesIcon(
                    iconData: _getIconData(state.overallState),
                    primaryColor: _getColor(state.overallState),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.statusText,
                    style: TextStyle(
                      color: _getColor(state.overallState),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRelayDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<RelayBloc>(),
          child: const RelayListDialog(),
        ),
      ),
    );
  }

  NesIconData _getIconData(ConnectionState state) {
    return switch (state) {
      ConnectionState.connected => NesIcons.radio,
      ConnectionState.connecting => NesIcons.hourglassMiddle,
      ConnectionState.reconnecting => NesIcons.hourglassMiddle,
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

  String _getTooltipMessage(RelayState state) {
    return '${state.connectedCount}/${state.totalCount} relays connected';
  }
}
