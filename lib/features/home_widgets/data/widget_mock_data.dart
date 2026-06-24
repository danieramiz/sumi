import 'package:sumi_app/features/home_widgets/data/sumi_widget_entry.dart';

class WidgetMockData {
  WidgetMockData._();

  static final smallEntry = SumiWidgetEntry(
    title: 'Sumi',
    subtitle: '3 new chapters',
    newChapterCount: 3,
  );

  static final mediumEntry = SumiWidgetEntry(
    title: 'Continue Reading',
    subtitle: 'Vagabond',
    coverUrl:
        'https://uploads.mangadex.org/covers/0a7ae358-5db0-4e17-99c4-0f91f0b3e4d2/a502c7e4-0f7a-4630-b85d-842427bd057f.jpg',
    chapterLabel: 'Ch. 327',
    progress: 0.92,
    newChapterCount: 0,
  );

  static final largeEntry = SumiWidgetEntry(
    title: 'Today in Sumi',
    subtitle: '3 new chapters today',
    newChapterCount: 3,
    updates: [
      SumiChapterUpdate(
        mangaTitle: 'Chainsaw Man',
        chapterLabel: 'Ch. 232',
        timeAgo: '2h ago',
      ),
      SumiChapterUpdate(
        mangaTitle: 'Kingdom',
        chapterLabel: 'Ch. 865',
        timeAgo: '4h ago',
      ),
      SumiChapterUpdate(
        mangaTitle: 'Frieren',
        chapterLabel: 'Ch. 128',
        timeAgo: '6h ago',
      ),
    ],
  );
}

SumiWidgetEntry buildWidgetEntryFromLibrary({
  required List<dynamic> mangaList,
  required List<dynamic> recentlyUpdated,
}) {
  return WidgetMockData.largeEntry;
}
