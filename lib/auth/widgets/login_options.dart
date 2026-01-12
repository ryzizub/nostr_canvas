import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/about/about.dart';
import 'package:nostr_canvas/auth/auth.dart';
import 'package:nostr_canvas/auth/widgets/import_key_dialog.dart';
import 'package:nostr_client/nostr_client.dart' show Nip07Signer;

/// Login options container with guest, import, and NIP-07 buttons.
class LoginOptions extends StatelessWidget {
  const LoginOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return const NesContainer(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AppLogo(),
          SizedBox(height: 8),
          _AppTitle(),
          SizedBox(height: 24),
          _GuestButton(),
          SizedBox(height: 12),
          _ImportKeyButton(),
          SizedBox(height: 12),
          _Nip07Button(),
          SizedBox(height: 16),
          InfoButton(),
        ],
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return NesIcon(
      iconData: NesIcons.edit,
      size: const Size.square(48),
      primaryColor: Colors.white,
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Nostr Canvas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Collaborative Pixel Canvas',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _GuestButton extends StatelessWidget {
  const _GuestButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: NesButton(
        type: NesButtonType.primary,
        onPressed: () {
          context.read<AuthBloc>().add(const AuthGuestRequested());
        },
        child: const Text('Guest'),
      ),
    );
  }
}

class _ImportKeyButton extends StatelessWidget {
  const _ImportKeyButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: NesButton(
        type: NesButtonType.normal,
        onPressed: () => _showImportDialog(context),
        child: const Text('Import Key'),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => ImportKeyDialog(
          onImport: (nsec) {
            context.read<AuthBloc>().add(AuthImportRequested(nsec));
          },
        ),
      ),
    );
  }
}

class _Nip07Button extends StatelessWidget {
  const _Nip07Button();

  @override
  Widget build(BuildContext context) {
    final isAvailable = Nip07Signer.isAvailable;

    return SizedBox(
      width: 200,
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5,
        child: NesButton(
          type: NesButtonType.normal,
          onPressed: isAvailable
              ? () {
                  context.read<AuthBloc>().add(const AuthNip07Requested());
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('NIP-07'),
              if (!isAvailable) ...[
                const SizedBox(width: 8),
                const Tooltip(
                  message: 'Browser extension not detected',
                  child: Icon(Icons.info_outline, size: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
