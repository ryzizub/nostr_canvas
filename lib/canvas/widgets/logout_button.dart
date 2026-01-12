import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_place/auth/auth.dart';

/// Button to log out and return to login screen.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return NesIconButton(
      icon: NesIcons.delete,
      onPress: () => _showLogoutConfirmation(context),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    unawaited(showDialog<void>(
      context: context,
      builder: (dialogContext) => Center(
        child: Material(
          color: Colors.transparent,
          child: NesContainer(
            width: 280,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NesIcon(
                  iconData: NesIcons.delete,
                  size: const Size.square(32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NesButton(
                      type: NesButtonType.normal,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    NesButton(
                      type: NesButtonType.error,
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context
                            .read<AuthBloc>()
                            .add(const AuthLogoutRequested());
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
