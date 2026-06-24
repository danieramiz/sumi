import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/features/widgets/data/widget_mock_data.dart';
import 'package:sumi_app/features/widgets/presentation/widgets/sumi_small_widget_preview.dart';

void main() {
  testWidgets('SumiSmallWidgetPreview shows logo and chapter count',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SumiSmallWidgetPreview(entry: WidgetMockData.smallEntry),
          ),
        ),
      ),
    );

    expect(find.text('3 new chapters'), findsOneWidget);
  });
}
