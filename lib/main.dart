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
import 'package:relay_settings_repository/relay_settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // HydratedBloc for color selection persistence
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory.web,
  );

  Bloc.observer = const AppBlocObserver();

  // Initialize relay settings repository
  final relaySettingsRepository = RelaySettingsRepository();
  await relaySettingsRepository.init();

  // Get saved relay URLs
  final relayUrls = relaySettingsRepository.getRelays();

  // Create shared RelayPool (uninitialized)
  final relayPool = RelayPool();

  // Create pixel repository with shared relay pool
  final pixelRepository = PixelRepository(
    canvasWidth: Constants.canvasWidth,
    canvasHeight: Constants.canvasHeight,
    relayPool: relayPool,
  );

  // Create auth repository with shared relay pool
  final authRepository = AuthRepository(
    relayPool: relayPool,
    pixelRepository: pixelRepository,
    initialRelayUrls: relayUrls,
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
        RepositoryProvider<RelaySettingsRepository>.value(
          value: relaySettingsRepository,
        ),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: App(router: router),
      ),
    ),
  );
}
