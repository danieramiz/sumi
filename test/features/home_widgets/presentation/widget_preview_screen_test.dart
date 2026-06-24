import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/features/home_widgets/presentation/widget_preview_screen.dart';

void main() {
  testWidgets('WidgetPreviewScreen renders sections and button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WidgetPreviewScreen()),
    );

    expect(find.text('Widget Preview'), findsOneWidget);
    expect(find.text('Small Widget'), findsOneWidget);
    expect(find.text('Medium Widget'), findsOneWidget);
    expect(find.text('Large Widget'), findsOneWidget);
  });
}
