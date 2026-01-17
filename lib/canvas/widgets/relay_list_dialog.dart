import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/canvas/bloc/relay_bloc.dart';
import 'package:nostr_client/nostr_client.dart';

/// Dialog for managing relay connections.
class RelayListDialog extends StatefulWidget {
  const RelayListDialog({super.key});

  @override
  State<RelayListDialog> createState() => _RelayListDialogState();
}

class _RelayListDialogState extends State<RelayListDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addRelay() {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    if (!_isValidUrl(url)) {
      setState(() => _errorText = 'Invalid relay URL');
      return;
    }

    context.read<RelayBloc>().add(RelayAddRequested(url));
    _controller.clear();
    setState(() => _errorText = null);
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'wss' || uri.scheme == 'ws';
    } on Object {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 500),
          child: NesContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Relay Connections',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _RelayInput(
                  controller: _controller,
                  errorText: _errorText,
                  onAdd: _addRelay,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: BlocBuilder<RelayBloc, RelayState>(
                    builder: (context, state) {
                      return _RelayList(
                        relayStates: state.relayStates,
                        canRemove: state.totalCount > 1,
                        onRemove: (url) => context.read<RelayBloc>().add(
                          RelayRemoveRequested(url),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                NesButton(
                  type: NesButtonType.normal,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelayInput extends StatelessWidget {
  const _RelayInput({
    required this.controller,
    required this.errorText,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'wss://relay.example.com',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            NesIconButton(
              icon: NesIcons.add,
              onPress: onAdd,
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _RelayList extends StatelessWidget {
  const _RelayList({
    required this.relayStates,
    required this.canRemove,
    required this.onRemove,
  });

  final Map<String, ConnectionState> relayStates;
  final bool canRemove;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final entries = relayStates.entries.toList();

    if (entries.isEmpty) {
      return const Center(
        child: Text('No relays configured'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _RelayListItem(
          url: entry.key,
          state: entry.value,
          canRemove: canRemove,
          onRemove: () => onRemove(entry.key),
        );
      },
    );
  }
}

class _RelayListItem extends StatelessWidget {
  const _RelayListItem({
    required this.url,
    required this.state,
    required this.canRemove,
    required this.onRemove,
  });

  final String url;
  final ConnectionState state;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return NesContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _StatusDot(state: state),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (canRemove)
            NesIconButton(
              icon: NesIcons.close,
              onPress: onRemove,
              size: const Size.square(16),
            ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.state});

  final ConnectionState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColor(state),
      ),
    );
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
}
