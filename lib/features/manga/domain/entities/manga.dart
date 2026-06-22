enum ReadingStatus {
  reading,
  onHold,
  completed,
  planned,
  dropped,
  caughtUp,
}

class Arc {
  final String name;
  final double startChapter;
  final double? endChapter;
  final String? imageUrl;
  final double progress;

  const Arc({
    required this.name,
    required this.startChapter,
    this.endChapter,
    this.imageUrl,
    required this.progress,
  });
}

class Character {
  final String name;
  final String? imageUrl;
  final bool isFavorite;

  const Character({
    required this.name,
    this.imageUrl,
    this.isFavorite = false,
  });
}

class Manga {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String description;
  final List<String> genres;
  final ReadingStatus status;
  final double currentChapter;
  final double? totalChapters;
  final double progress;
  final DateTime lastUpdate;
  final double? rating;
  final int? popularity;
  final int? followers;
  final DateTime? readingSince;
  final Duration? totalReadingTime;
  final Arc? currentArc;
  final Character? topCharacter;
  final bool hasNewChapter;
  final String? nextChapterInfo;

  const Manga({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.description,
    required this.genres,
    required this.status,
    required this.currentChapter,
    this.totalChapters,
    required this.progress,
    required this.lastUpdate,
    this.rating,
    this.popularity,
    this.followers,
    this.readingSince,
    this.totalReadingTime,
    this.currentArc,
    this.topCharacter,
    this.hasNewChapter = false,
    this.nextChapterInfo,
  });
}
