class SumiWidgetEntry {
  final String title;
  final String subtitle;
  final String? coverUrl;
  final String? chapterLabel;
  final double? progress;
  final int newChapterCount;
  final List<SumiChapterUpdate> updates;

  SumiWidgetEntry({
    required this.title,
    required this.subtitle,
    this.coverUrl,
    this.chapterLabel,
    this.progress,
    this.newChapterCount = 0,
    this.updates = const [],
  });

  SumiWidgetEntry copyWith({
    String? title,
    String? subtitle,
    String? coverUrl,
    String? chapterLabel,
    double? progress,
    int? newChapterCount,
    List<SumiChapterUpdate>? updates,
  }) {
    return SumiWidgetEntry(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      coverUrl: coverUrl ?? this.coverUrl,
      chapterLabel: chapterLabel ?? this.chapterLabel,
      progress: progress ?? this.progress,
      newChapterCount: newChapterCount ?? this.newChapterCount,
      updates: updates ?? this.updates,
    );
  }
}

class SumiChapterUpdate {
  final String mangaTitle;
  final String chapterLabel;
  final String timeAgo;
  final String? coverUrl;

  SumiChapterUpdate({
    required this.mangaTitle,
    required this.chapterLabel,
    required this.timeAgo,
    this.coverUrl,
  });
}
