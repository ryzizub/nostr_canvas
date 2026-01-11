import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:nostr_place/app/app.dart';
import 'package:nostr_place/app/app_bloc_observer.dart';
import 'package:nostr_place/core/constants.dart';
import 'package:pixel_repository/pixel_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory.web,
  );

  Bloc.observer = const AppBlocObserver();

  // Initialize Nostr client
  final nostrClient = NostrClient(
    relayUrl: 'wss://relay.ryzizub.com',
    keychain: Keychain.generate(),
    powDifficulty: 16,
  );

  await nostrClient.connect();

  final pixelRepository = PixelRepository(
    nostrClient: nostrClient,
    canvasWidth: Constants.canvasWidth,
    canvasHeight: Constants.canvasHeight,
  );

  runApp(
    RepositoryProvider<PixelRepository>.value(
      value: pixelRepository,
      child: const App(),
    ),
  );
}
