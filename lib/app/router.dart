import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nostr_canvas/auth/auth.dart';
import 'package:nostr_canvas/canvas/canvas.dart';

/// Creates the app router with authentication redirect logic.
///
/// The router redirects to /login if not authenticated,
/// and to / (canvas) if authenticated and on login page.
GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefreshNotifier(authBloc),
    redirect: (context, state) {
      final isAuthenticated = authBloc.state.status == AuthStatus.authenticated;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) {
        return '/login';
      }
      if (isAuthenticated && isOnLogin) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => BlocProvider.value(
          value: authBloc,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const CanvasPage(),
      ),
    ],
  );
}

/// Notifies GoRouter when auth state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._authBloc) {
    _authBloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _authBloc;
}
