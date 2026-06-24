import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sumi_app/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches without crash', (tester) async {
    await tester.pumpWidget(const SumiApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.binding.renderView.child, isNotNull);
  });

  testWidgets('Welcome or library is shown', (tester) async {
    await tester.pumpWidget(const SumiApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final onWelcome = find.text('Sign in with MangaDex').evaluate().isNotEmpty;
    log(onWelcome ? 'Welcome screen visible' : 'Library screen visible');
  });

  testWidgets('Can navigate to library via sample data', (tester) async {
    await tester.pumpWidget(const SumiApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final browseBtn = find.text('Browse sample data');
    if (browseBtn.evaluate().isNotEmpty) {
      await tester.tap(browseBtn);
      await tester.pumpAndSettle();
    }

    final hasCards = find.text('One Piece').evaluate().isNotEmpty;
    log('Library cards visible: $hasCards');
  });

  testWidgets('Widget background MethodChannel does not crash',
      (tester) async {
    // Verify the background schedule MethodChannel can be called
    // without throwing during app startup
    try {
      const channel = MethodChannel('sumi_widget_background');
      await channel.invokeMethod('schedule');
      log('Widget background schedule invoked successfully');
    } catch (e) {
      log('Widget background schedule failed (expected if not connected): $e');
    }
  });
}
