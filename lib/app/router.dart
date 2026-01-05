import 'package:go_router/go_router.dart';
import 'package:nostr_place/canvas/canvas.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const CanvasPage(),
    ),
  ],
);
