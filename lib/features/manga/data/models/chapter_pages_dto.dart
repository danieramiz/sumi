class ChapterPagesDto {
  final String baseUrl;
  final String hash;
  final List<String> pages;
  final List<String> dataSaverPages;

  ChapterPagesDto({
    required this.baseUrl,
    required this.hash,
    required this.pages,
    required this.dataSaverPages,
  });

  factory ChapterPagesDto.fromJson(Map<String, dynamic> json) {
    final chapter = json['chapter'] as Map<String, dynamic>? ?? {};
    final data = chapter['data'] as List<dynamic>? ?? [];
    final dataSaver = chapter['dataSaver'] as List<dynamic>? ?? [];
    return ChapterPagesDto(
      baseUrl: json['baseUrl'] as String? ?? '',
      hash: chapter['hash'] as String? ?? '',
      pages: data.map((e) => e.toString()).toList(),
      dataSaverPages: dataSaver.map((e) => e.toString()).toList(),
    );
  }

  List<String> qualityUrls() {
    return pages.map((p) => '$baseUrl/data/$hash/$p').toList();
  }

  List<String> dataSaverUrls() {
    return dataSaverPages.map((p) => '$baseUrl/data-saver/$hash/$p').toList();
  }
}
