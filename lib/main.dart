import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:nostr_canvas/app/app.dart';
import 'package:nostr_canvas/app/app_bloc_observer.dart';
import 'package:nostr_canvas/app/router.dart';
import 'package:nostr_canvas/auth/auth.dart';
import 'package:nostr_canvas/core/constants.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // HydratedBloc for color selection persistence
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory.web,
  );

  Bloc.observer = const AppBlocObserver();

  // Create shared NostrClient (uninitialized)
  final nostrClient = NostrClient();

  // Create pixel repository with shared client
  final pixelRepository = PixelRepository(
    canvasWidth: Constants.canvasWidth,
    canvasHeight: Constants.canvasHeight,
    nostrClient: nostrClient,
  );

  // Create auth repository with shared client
  final authRepository = AuthRepository(
    nostrClient: nostrClient,
    pixelRepository: pixelRepository,
    relayUrl: Constants.relayUrl,
    powDifficulty: Constants.powDifficulty,
  );

  // Create AuthBloc and check for stored credentials
  final authBloc = AuthBloc(authRepository: authRepository)
    ..add(const AuthCheckRequested());

  // Wait for initial auth check to complete
  await authBloc.stream.firstWhere(
    (state) => state.status != AuthStatus.initial,
  );

  final router = createAppRouter(authBloc);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<PixelRepository>.value(value: pixelRepository),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: App(router: router),
      ),
    ),
  );
}
