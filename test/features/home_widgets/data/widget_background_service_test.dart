import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final savedData = <String, dynamic>{};

  setUp(() {
    savedData.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'saveWidgetData':
            savedData[methodCall.arguments['id']] =
                methodCall.arguments['data'];
            return true;
          case 'updateWidget':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      null,
    );
  });

  test('mockData returns 3 updates', () {
    final data = SumiWidgetService.mockData();
    expect(data.newChapterCount, 3);
    expect(data.updates.length, 3);
    expect(data.updates[0].mangaTitle, 'Chainsaw Man');
    expect(data.updates[1].mangaTitle, 'Kingdom');
    expect(data.updates[2].mangaTitle, 'Frieren');
  });

  test('updateAndroidWidgets saves update data correctly', () async {
    final data = SumiWidgetService.mockData();
    await SumiWidgetService().updateAndroidWidgets(data);

    expect(savedData['update_1_title'], 'Chainsaw Man');
    expect(savedData['update_1_chapter'], 'Ch. 232');
    expect(savedData['update_1_time'], '2h ago');
    expect(savedData['update_2_title'], 'Kingdom');
    expect(savedData['update_3_title'], 'Frieren');
  });
}
