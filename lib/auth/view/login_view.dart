import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_place/auth/auth.dart';
import 'package:nostr_place/auth/widgets/login_options.dart';

/// Main view for the login screen.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212529),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            curr.status == AuthStatus.authenticated ||
            curr.status == AuthStatus.error,
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go('/');
          } else if (state.status == AuthStatus.error &&
              state.errorMessage != null) {
            _showErrorDialog(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          return Center(
            child: switch (state.status) {
              AuthStatus.initial => const NesHourglassLoadingIndicator(),
              AuthStatus.authenticating => const _AuthenticatingIndicator(),
              AuthStatus.unauthenticated ||
              AuthStatus.error =>
                const LoginOptions(),
              AuthStatus.authenticated => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
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
                  iconData: NesIcons.close,
                  size: const Size.square(32),
                  primaryColor: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                NesButton(
                  type: NesButtonType.error,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.read<AuthBloc>().add(const AuthErrorCleared());
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class _AuthenticatingIndicator extends StatelessWidget {
  const _AuthenticatingIndicator();

  @override
  Widget build(BuildContext context) {
    return NesContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NesHourglassLoadingIndicator(),
          const SizedBox(height: 16),
          Text(
            'Authenticating...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
