class MangaDto {
  final String id;
  final Map<String, String> title;
  final Map<String, String> description;
  final String? status;
  final double? lastChapter;
  final List<String> genres;
  final String? coverFileName;
  final String? author;

  MangaDto({
    required this.id,
    required this.title,
    required this.description,
    this.status,
    this.lastChapter,
    required this.genres,
    this.coverFileName,
    this.author,
  });

  String get preferredTitle {
    return title['en'] ?? title.values.firstOrNull ?? 'Unknown';
  }

  String get preferredDescription {
    return description['en'] ?? description.values.firstOrNull ?? '';
  }

  factory MangaDto.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    final titleRaw = attributes['title'] as Map<String, dynamic>? ?? {};
    final descRaw = attributes['description'] as Map<String, dynamic>? ?? {};
    final tags = attributes['tags'] as List<dynamic>? ?? [];
    final relationships = json['relationships'] as List<dynamic>? ?? [];

    String? coverFileName;
    String? author;
    for (final rel in relationships) {
      final relMap = rel as Map<String, dynamic>;
      final type = relMap['type'] as String?;
      if (type == 'cover_art') {
        final relAttr = relMap['attributes'] as Map<String, dynamic>?;
        coverFileName = relAttr?['fileName'] as String?;
      } else if (type == 'author') {
        final relAttr = relMap['attributes'] as Map<String, dynamic>?;
        author = relAttr?['name'] as String?;
      }
    }

    final status = attributes['status'] as String?;
    double? lastChapter;
    final lc = attributes['lastChapter'] as String?;
    if (lc != null) {
      lastChapter = double.tryParse(lc);
    }

    return MangaDto(
      id: json['id'] as String,
      title: titleRaw.map((k, v) => MapEntry(k, v.toString())),
      description: descRaw.map((k, v) => MapEntry(k, v.toString())),
      status: status,
      lastChapter: lastChapter,
      genres: tags
          .map((t) => t as Map<String, dynamic>)
          .map((t) {
            final attr = t['attributes'] as Map<String, dynamic>? ?? {};
            final name = attr['name'] as Map<String, dynamic>? ?? {};
            return name['en'] as String? ?? '';
          })
          .where((n) => n.isNotEmpty)
          .toList(),
      coverFileName: coverFileName,
      author: author,
    );
  }
}

class MangaSearchResponse {
  final List<MangaDto> data;
  final int total;

  MangaSearchResponse({required this.data, required this.total});

  factory MangaSearchResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return MangaSearchResponse(
      data: dataList
          .map((e) => MangaDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}
