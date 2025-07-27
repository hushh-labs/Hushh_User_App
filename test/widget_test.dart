// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hushh_user_app/di/core_module.dart';
import 'package:hushh_user_app/core/routing/navigation_service.dart';
import 'package:hushh_user_app/core/routing/route_paths.dart';

void main() {
  group('Dependency Injection Tests', () {
    setUpAll(() {
      // Initialize only core module (no Firebase dependencies)
      CoreModule.register();
    });

    test('NavigationService should be registered', () {
      final navigationService = GetIt.instance<NavigationService>();
      expect(navigationService, isNotNull);
      expect(navigationService, isA<NavigationService>());
    });

    test('DI should resolve navigation service', () {
      // This test verifies that navigation service can be resolved
      expect(() => GetIt.instance<NavigationService>(), returnsNormally);
    });

    test('Route names should be correctly defined', () {
      // Verify that route names are properly defined
      expect(RouteNames.otpVerification, equals('otpVerification'));
      expect(RoutePaths.otpVerification, equals('/otp-verification'));
    });
  });
}
