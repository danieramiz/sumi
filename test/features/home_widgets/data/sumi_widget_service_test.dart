import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_data.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SumiWidgetService service;
  final savedData = <String, dynamic>{};

  setUp(() {
    service = SumiWidgetService();
    savedData.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'saveWidgetData':
            final id = methodCall.arguments['id'] as String;
            final data = methodCall.arguments['data'];
            savedData[id] = data;
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

  test('mockData returns expected structure', () {
    final mock = SumiWidgetService.mockData();
    expect(mock.newChapterCount, 3);
    expect(mock.continueReading, isNotNull);
    expect(mock.continueReading!.title, 'Vagabond');
    expect(mock.continueReading!.chapterLabel, 'Ch. 327');
    expect(mock.updates.length, 3);
  });

  test('updateAndroidWidgets saves data and triggers update', () async {
    final data = SumiWidgetData(
      newChapterCount: 2,
      continueReading: MangaWidgetItem(
        title: 'Berserk',
        chapterLabel: 'Ch. 364',
        coverUrl: 'https://example.com/berserk.jpg',
        progress: 0.75,
      ),
      updates: [
        ChapterWidgetUpdate(
          mangaTitle: 'Berserk',
          chapterLabel: 'Ch. 364',
          timeAgo: '1h ago',
        ),
      ],
    );

    await service.updateAndroidWidgets(data);

    expect(savedData['new_chapter_count'], 2);
    expect(savedData['continue_title'], 'Berserk');
    expect(savedData['continue_chapter'], 'Ch. 364');
    expect(savedData['continue_percentage'], 75);
  });

  test('updateAndroidWidgets handles null continueReading', () async {
    final data = SumiWidgetData(newChapterCount: 0);

    await service.updateAndroidWidgets(data);

    expect(savedData['new_chapter_count'], 0);
    expect(savedData['continue_title'], '');
    expect(savedData['continue_chapter'], '');
    expect(savedData['continue_percentage'], 0);
  });
}
