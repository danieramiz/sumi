class ChapterDto {
  final String id;
  final String? chapter;
  final String? title;
  final String? publishDate;
  final String? translatedLanguage;

  ChapterDto({
    required this.id,
    this.chapter,
    this.title,
    this.publishDate,
    this.translatedLanguage,
  });

  double? get chapterNumber {
    if (chapter == null) return null;
    return double.tryParse(chapter!);
  }

  factory ChapterDto.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    return ChapterDto(
      id: json['id'] as String,
      chapter: attributes['chapter'] as String?,
      title: attributes['title'] as String?,
      publishDate: attributes['publishAt'] as String?,
      translatedLanguage: attributes['translatedLanguage'] as String?,
    );
  }
}

class ChapterFeedResponse {
  final List<ChapterDto> data;

  ChapterFeedResponse({required this.data});

  factory ChapterFeedResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return ChapterFeedResponse(
      data: dataList
          .map((e) => ChapterDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
