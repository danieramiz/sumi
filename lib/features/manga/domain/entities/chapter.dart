class Chapter {
  final String id;
  final double chapterNumber;
  final String? title;
  final DateTime? publishDate;
  final bool isRead;

  const Chapter({
    required this.id,
    required this.chapterNumber,
    this.title,
    this.publishDate,
    this.isRead = false,
  });
}
