import 'dart:typed_data';

class SumiWidgetData {
  final int newChapterCount;
  final MangaWidgetItem? continueReading;
  final List<ChapterWidgetUpdate> updates;

  SumiWidgetData({
    this.newChapterCount = 0,
    this.continueReading,
    this.updates = const [],
  });
}

class MangaWidgetItem {
  final String title;
  final String chapterLabel;
  final String coverUrl;
  final double progress;

  MangaWidgetItem({
    required this.title,
    required this.chapterLabel,
    this.coverUrl = '',
    this.progress = 0.0,
  });
}

class ChapterWidgetUpdate {
  final String mangaTitle;
  final String chapterLabel;
  final String timeAgo;

  ChapterWidgetUpdate({
    required this.mangaTitle,
    required this.chapterLabel,
    required this.timeAgo,
  });
}

class WidgetCoverImage {
  final String filePath;
  final Uint8List bytes;

  WidgetCoverImage({required this.filePath, required this.bytes});
}
