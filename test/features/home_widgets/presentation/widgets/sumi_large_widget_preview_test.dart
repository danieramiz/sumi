import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/features/home_widgets/data/widget_mock_data.dart';
import 'package:sumi_app/features/home_widgets/presentation/widgets/sumi_large_widget_preview.dart';

void main() {
  testWidgets('SumiLargeWidgetPreview shows header and updates',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SumiLargeWidgetPreview(entry: WidgetMockData.largeEntry),
          ),
        ),
      ),
    );

    expect(find.text('Today in Sumi'), findsOneWidget);
    expect(find.text('3 new chapters today'), findsOneWidget);
    expect(find.text('Chainsaw Man'), findsOneWidget);
    expect(find.text('Kingdom'), findsOneWidget);
    expect(find.text('Frieren'), findsOneWidget);
  });
}
