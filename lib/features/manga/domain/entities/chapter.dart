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

  Chapter copyWith({
    String? id,
    double? chapterNumber,
    String? title,
    DateTime? publishDate,
    bool? isRead,
  }) {
    return Chapter(
      id: id ?? this.id,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      publishDate: publishDate ?? this.publishDate,
      isRead: isRead ?? this.isRead,
    );
  }
}
