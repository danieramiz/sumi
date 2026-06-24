import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/features/widgets/data/widget_mock_data.dart';
import 'package:sumi_app/features/widgets/presentation/widgets/sumi_medium_widget_preview.dart';

void main() {
  testWidgets('SumiMediumWidgetPreview shows title and chapter info',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SumiMediumWidgetPreview(entry: WidgetMockData.mediumEntry),
          ),
        ),
      ),
    );

    expect(find.text('Continue Reading'), findsOneWidget);
    expect(find.text('Vagabond'), findsOneWidget);
    expect(find.text('Ch. 327'), findsOneWidget);
    expect(find.text('92% caught up'), findsOneWidget);
  });
}
