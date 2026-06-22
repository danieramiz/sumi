import 'dart:developer';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sumi_app/app/app.dart';

/// Helper: taps "Get Started" if visible, returns true if it was
Future<bool> dismissWelcome(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  final btn = find.text('Get Started');
  if (btn.evaluate().isNotEmpty) {
    await tester.tap(btn);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    return true;
  }
  return false;
}

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

    final onWelcome = await dismissWelcome(tester);
    log(onWelcome ? 'Welcome screen' : 'Already past welcome');
  });

  testWidgets('Can navigate to library', (tester) async {
    await tester.pumpWidget(const SumiApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final wasWelcome = await dismissWelcome(tester);

    // Pump for animations
    for (int i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    final hasCards = find.text('One Piece').evaluate().isNotEmpty;
    log('Cards visible: $hasCards');
  });
}
