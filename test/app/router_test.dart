import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_place/app/router.dart';

void main() {
  group('appRouter', () {
    test('can be instantiated', () {
      expect(appRouter, isNotNull);
      expect(appRouter.routeInformationProvider, isNotNull);
    });

    test('has routes configured', () {
      final routes = appRouter.configuration.routes;
      expect(routes, isNotEmpty);
    });
  });
}
