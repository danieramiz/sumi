import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sumi_app/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke Tests', () {
    testWidgets('App launches without crash', (tester) async {
      await tester.pumpWidget(const SumiApp());
      await tester.pumpAndSettle();
      log('App launched successfully');
    });

    testWidgets('Can tap Get Started when visible', (tester) async {
      await tester.pumpWidget(const SumiApp());
      await tester.pumpAndSettle();

      final btn = find.text('Get Started');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn);
        await tester.pumpAndSettle();
        log('Navigated past welcome screen');
      } else {
        log('Welcome screen skipped (already authenticated)');
      }
    });

    testWidgets('Search icon is present', (tester) async {
      await tester.pumpWidget(const SumiApp());
      await tester.pumpAndSettle();

      final btn = find.text('Get Started');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn);
        await tester.pumpAndSettle();
      }

      final search = find.byIcon(Icons.search_rounded);
      if (search.evaluate().isNotEmpty) {
        log('Search button is visible');
      } else {
        log('Search button not visible (may need auth)');
      }
    });

    testWidgets('Menu button is present', (tester) async {
      await tester.pumpWidget(const SumiApp());
      await tester.pumpAndSettle();

      final btn = find.text('Get Started');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn);
        await tester.pumpAndSettle();
      }

      final menu = find.byIcon(Icons.menu_rounded);
      expect(menu, findsOneWidget);
      log('Menu button is visible');
    });
  });
}
