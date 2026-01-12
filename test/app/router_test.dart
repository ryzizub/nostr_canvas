import 'dart:async' show unawaited;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_canvas/app/router.dart';
import 'package:nostr_canvas/auth/auth.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockNostrClient extends Mock implements NostrClient {}

void main() {
  group('createAppRouter', () {
    late FlutterSecureStorage mockStorage;
    late MockNostrClient mockNostrClient;
    late PixelRepository pixelRepository;
    late AuthRepository authRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      mockNostrClient = MockNostrClient();
      when(() => mockNostrClient.isInitialized).thenReturn(false);
      when(() => mockNostrClient.deinitialize()).thenAnswer((_) async {});

      pixelRepository = PixelRepository(
        canvasWidth: 100,
        canvasHeight: 100,
        nostrClient: mockNostrClient,
      );

      authRepository = AuthRepository(
        storage: mockStorage,
        nostrClient: mockNostrClient,
        pixelRepository: pixelRepository,
        relayUrl: 'wss://test.relay',
        powDifficulty: 0,
      );
      authBloc = AuthBloc(authRepository: authRepository);
    });

    tearDown(() {
      unawaited(authBloc.close());
      unawaited(pixelRepository.dispose());
    });

    test('can be instantiated', () {
      final router = createAppRouter(authBloc);
      expect(router, isNotNull);
      expect(router.routeInformationProvider, isNotNull);
    });

    test('has routes configured', () {
      final router = createAppRouter(authBloc);
      final routes = router.configuration.routes;
      expect(routes, isNotEmpty);
      expect(routes.length, 2); // /login and /
    });

    test('has login route', () {
      final router = createAppRouter(authBloc);
      final routes = router.configuration.routes;
      final goRoutes = routes.whereType<GoRoute>().toList();
      final paths = goRoutes.map((r) => r.path).toList();
      expect(paths, contains('/login'));
    });

    test('has home route', () {
      final router = createAppRouter(authBloc);
      final routes = router.configuration.routes;
      final goRoutes = routes.whereType<GoRoute>().toList();
      final paths = goRoutes.map((r) => r.path).toList();
      expect(paths, contains('/'));
    });
  });
}
