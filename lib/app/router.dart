import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const _PlaceholderHomePage(),
    ),
  ],
);

class _PlaceholderHomePage extends StatelessWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Place'),
      ),
      body: const Center(
        child: Text(
          'Welcome to Nostr Place\n\nCollaborative Pixel Canvas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
