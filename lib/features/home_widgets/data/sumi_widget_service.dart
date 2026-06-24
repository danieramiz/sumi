import 'package:home_widget/home_widget.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_data.dart';
import 'package:sumi_app/features/home_widgets/data/widget_image_service.dart';

class SumiWidgetService {
  static const _smallWidget = 'SumiSmallWidgetProvider';
  static const _mediumWidget = 'SumiMediumWidgetProvider';
  static const _largeWidget = 'SumiLargeWidgetProvider';

  Future<void> updateAndroidWidgets(SumiWidgetData data) async {
    await _saveData(data);
    await _triggerUpdates();
  }

  Future<void> _saveData(SumiWidgetData data) async {
    await HomeWidget.saveWidgetData<int>('new_chapter_count', data.newChapterCount);

    final manga = data.continueReading;
    if (manga != null) {
      await HomeWidget.saveWidgetData<String>('continue_title', manga.title);
      await HomeWidget.saveWidgetData<String>('continue_chapter', manga.chapterLabel);
      await HomeWidget.saveWidgetData<int>('continue_percentage',
          (manga.progress * 100).round());

      final coverPath = await WidgetImageService.downloadCover(manga.coverUrl);
      await HomeWidget.saveWidgetData<String>('continue_cover_path', coverPath ?? '');
    } else {
      await HomeWidget.saveWidgetData<String>('continue_title', '');
      await HomeWidget.saveWidgetData<String>('continue_chapter', '');
      await HomeWidget.saveWidgetData<String>('continue_cover_path', '');
      await HomeWidget.saveWidgetData<int>('continue_percentage', 0);
    }

    for (int i = 0; i < 3; i++) {
      final idx = i + 1;
      if (i < data.updates.length) {
        final u = data.updates[i];
        await HomeWidget.saveWidgetData<String>('update_${idx}_title', u.mangaTitle);
        await HomeWidget.saveWidgetData<String>('update_${idx}_chapter', u.chapterLabel);
        await HomeWidget.saveWidgetData<String>('update_${idx}_time', u.timeAgo);
      } else {
        await HomeWidget.saveWidgetData<String>('update_${idx}_title', '');
        await HomeWidget.saveWidgetData<String>('update_${idx}_chapter', '');
        await HomeWidget.saveWidgetData<String>('update_${idx}_time', '');
      }
    }
  }

  Future<void> _triggerUpdates() async {
    await HomeWidget.updateWidget(name: _smallWidget, iOSName: _smallWidget);
    await HomeWidget.updateWidget(name: _mediumWidget, iOSName: _mediumWidget);
    await HomeWidget.updateWidget(name: _largeWidget, iOSName: _largeWidget);
  }

  static SumiWidgetData mockData() {
    return SumiWidgetData(
      newChapterCount: 3,
      continueReading: MangaWidgetItem(
        title: 'Vagabond',
        chapterLabel: 'Ch. 327',
        coverUrl:
            'https://uploads.mangadex.org/covers/0a7ae358-5db0-4e17-99c4-0f91f0b3e4d2/a502c7e4-0f7a-4630-b85d-842427bd057f.jpg',
        progress: 0.92,
      ),
      updates: [
        ChapterWidgetUpdate(
          mangaTitle: 'Chainsaw Man',
          chapterLabel: 'Ch. 232',
          timeAgo: '2h ago',
        ),
        ChapterWidgetUpdate(
          mangaTitle: 'Kingdom',
          chapterLabel: 'Ch. 865',
          timeAgo: '4h ago',
        ),
        ChapterWidgetUpdate(
          mangaTitle: 'Frieren',
          chapterLabel: 'Ch. 128',
          timeAgo: '6h ago',
        ),
      ],
    );
  }
}
