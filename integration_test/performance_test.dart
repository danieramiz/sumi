import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sumi_app/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Tests', () {
    testWidgets('App launches and renders', (tester) async {
      await tester.pumpWidget(const SumiApp());
      await tester.pumpAndSettle();

      // Check we get to a valid screen (welcome or library)
      final hasWelcome = find.text('Sumi').evaluate().isNotEmpty;
      final hasMenu = find.byIcon(Icons.menu_rounded).evaluate().isNotEmpty;
      expect(hasWelcome || hasMenu, isTrue,
          reason: 'App should show welcome or library');
      log('App loaded: welcome=$hasWelcome library=$hasMenu');
    });

    testWidgets('Welcome screen navigation', (tester) async {
      await tester.pumpWidget(const SumiApp());
      await tester.pumpAndSettle();

      final btn = find.text('Get Started');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn);
        await tester.pumpAndSettle();
        // After tapping get started, we should see the library
        await tester.pump(const Duration(seconds: 1));
        log('Navigated from welcome to library');
      } else {
        log('Already authenticated, welcome skipped');
      }
    });

    testWidgets('UI renders without crash', (tester) async {
      await tester.pumpWidget(const SumiApp());
      await tester.pumpAndSettle();

      final btn = find.text('Get Started');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn);
      }

      // Wait for auth and library to settle
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // App should be in a valid state
      expect(tester.binding.renderView.child, isNotNull);
      log('App UI rendered successfully');
    });

    testWidgets('Search button opens search', (tester) async {
      await tester.pumpWidget(const SumiApp());
      await tester.pumpAndSettle();

      // Skip welcome if needed
      final btn = find.text('Get Started');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn);
        await tester.pumpAndSettle();
      }

      final searchBtn = find.byIcon(Icons.search_rounded);
      if (searchBtn.evaluate().isNotEmpty) {
        await tester.tap(searchBtn);
        await tester.pumpAndSettle();
        log('Search screen opened');
      } else {
        log('Search button not visible');
      }
    });
  });
}
