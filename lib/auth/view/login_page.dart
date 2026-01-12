import 'package:flutter/material.dart';
import 'package:nostr_canvas/auth/view/login_view.dart';

/// Entry point page for the login feature.
///
/// Note: AuthBloc is provided by the router, not created here.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginView();
  }
}
