import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_data.dart';

void main() {
  group('SumiWidgetData', () {
    test('default values', () {
      final data = SumiWidgetData();
      expect(data.newChapterCount, 0);
      expect(data.continueReading, isNull);
      expect(data.updates, isEmpty);
    });

    test('constructs with all fields', () {
      final data = SumiWidgetData(
        newChapterCount: 3,
        continueReading: MangaWidgetItem(
          title: 'Vagabond',
          chapterLabel: 'Ch. 327',
          coverUrl: 'https://example.com/cover.jpg',
          progress: 0.92,
        ),
        updates: [
          ChapterWidgetUpdate(
            mangaTitle: 'Chainsaw Man',
            chapterLabel: 'Ch. 232',
            timeAgo: '2h ago',
          ),
        ],
      );
      expect(data.newChapterCount, 3);
      expect(data.continueReading!.title, 'Vagabond');
      expect(data.continueReading!.chapterLabel, 'Ch. 327');
      expect(data.continueReading!.coverUrl, 'https://example.com/cover.jpg');
      expect(data.continueReading!.progress, 0.92);
      expect(data.updates.length, 1);
      expect(data.updates.first.mangaTitle, 'Chainsaw Man');
    });
  });

  group('MangaWidgetItem', () {
    test('default coverUrl is empty', () {
      final item = MangaWidgetItem(title: 'Test', chapterLabel: 'Ch. 1');
      expect(item.coverUrl, '');
      expect(item.progress, 0.0);
    });
  });

  group('ChapterWidgetUpdate', () {
    test('constructs correctly', () {
      final update = ChapterWidgetUpdate(
        mangaTitle: 'One Piece',
        chapterLabel: 'Ch. 1100',
        timeAgo: '1d ago',
      );
      expect(update.mangaTitle, 'One Piece');
      expect(update.chapterLabel, 'Ch. 1100');
      expect(update.timeAgo, '1d ago');
    });
  });

  group('WidgetCoverImage', () {
    test('constructs with filePath and bytes', () {
      final image = WidgetCoverImage(
        filePath: '/tmp/cover.jpg',
        bytes: Uint8List.fromList([0, 1, 2]),
      );
      expect(image.filePath, '/tmp/cover.jpg');
      expect(image.bytes.length, 3);
    });
  });
}
