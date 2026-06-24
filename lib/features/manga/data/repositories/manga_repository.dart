import 'package:sumi_app/core/storage/preferences_service.dart';
import 'package:sumi_app/features/home_widgets/data/interfaces/widget_service.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_data.dart';
import 'package:sumi_app/features/manga/data/interfaces/manga_service.dart';
import 'package:sumi_app/features/manga/data/models/manga_dto.dart';
import 'package:sumi_app/features/manga/domain/entities/chapter.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/data/mock/mock_data.dart';

class MangaRepository {
  final MangaService _api;
  final PreferencesServiceBase _prefs;
  final WidgetService? _widgetService;

  MangaRepository({
    required MangaService api,
    required PreferencesServiceBase prefs,
    WidgetService? widgetService,
  })  : _api = api,
        _prefs = prefs,
        _widgetService = widgetService;

  List<Manga> sortLibrary(List<Manga> manga) {
    final pinned = _prefs.pinnedMangaIds;
    final sorted = List<Manga>.from(manga);
    if (_prefs.sortOrder == SortOrder.title) {
      sorted.sort((a, b) => a.title.compareTo(b.title));
    }
    sorted.sort((a, b) {
      final aPinned = pinned.contains(a.id) ? 0 : 1;
      final bPinned = pinned.contains(b.id) ? 0 : 1;
      return aPinned.compareTo(bPinned);
    });
    return sorted;
  }

  Future<List<Manga>> searchManga(String query, {int limit = 20}) async {
    final response = await _api.searchManga(title: query, limit: limit);
    return response.data.map(_fromDto).toList();
  }

  Future<List<Manga>> fetchFollowedManga(String token,
      {int limit = 100}) async {
    final response = await _api.getFollowedManga(token, limit: limit);
    return response.data.map(_fromDto).toList();
  }

  List<Manga> getMockLibrary() => mockMangaList;

  Future<Manga?> fetchMangaDetails(String id) async {
    try {
      final dto = await _api.getMangaDetails(id);
      return _fromDto(dto);
    } catch (_) {
      return null;
    }
  }

  Future<bool> followManga(String mangaId, String token) async {
    return _api.followManga(mangaId, token);
  }

  Future<bool> unfollowManga(String mangaId, String token) async {
    return _api.unfollowManga(mangaId, token);
  }

  Future<bool> setReadingStatus(
      String mangaId, String status, String token) async {
    return _api.setReadingStatus(mangaId, status, token);
  }

  Future<bool> togglePin(String id) async {
    if (_prefs.pinnedMangaIds.contains(id)) {
      _prefs.pinnedMangaIds.remove(id);
    } else {
      _prefs.pinnedMangaIds.add(id);
    }
    await _prefs.save();
    return _prefs.pinnedMangaIds.contains(id);
  }

  bool isPinned(String id) => _prefs.pinnedMangaIds.contains(id);

  Future<int> fetchTotalChapters(String mangaId,
      {String? token}) async {
    try {
      final lang = _prefs.language;
      final data = await _api.getMangaAggregate(mangaId, language: lang);
      return _api.parseTotalChapters(data);
    } catch (_) {
      return 0;
    }
  }

  Future<List<Chapter>> fetchChapters(String mangaId,
      {bool ascending = false, int offset = 0, int limit = 20}) async {
    try {
      final lang = _prefs.language;
      final dtos = await _api.getChapters(mangaId,
          limit: limit, offset: offset, ascending: ascending, language: lang);
      return dtos.map((d) => Chapter(
            id: d.id,
            chapterNumber: d.chapterNumber ?? 0,
            title: d.title,
            publishDate:
                d.publishDate != null ? DateTime.tryParse(d.publishDate!) : null,
            isRead: false,
          )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Set<String>> fetchReadChapters(
      String mangaId, String token) async {
    return _api.getReadChapters(mangaId, token);
  }

  Future<bool> markChapterRead(
      String mangaId, String chapterId, String token) async {
    return _api.markChapterRead(mangaId, chapterId, token);
  }

  Future<bool> markChaptersRead(
      String mangaId, List<String> chapterIds, String token) async {
    return _api.markChaptersRead(mangaId, chapterIds, token);
  }

  Future<List<Chapter>> fetchChaptersWithReadStatus(
    String mangaId, {
    String? token,
    bool ascending = false,
    int offset = 0,
    int limit = 20,
  }) async {
    final chapters = await fetchChapters(mangaId,
        ascending: ascending, offset: offset, limit: limit);
    if (token != null) {
      final readIds = await fetchReadChapters(mangaId, token);
      return chapters.map((c) => c.copyWith(isRead: readIds.contains(c.id))).toList();
    }
    return chapters;
  }

  void updateWidgets(List<Manga> manga) {
    final list = manga;
    if (list.isEmpty || _widgetService == null) return;
    final widgetService = _widgetService;

    final now = DateTime.now();
    final recentUpdates =
        list.where((m) => now.difference(m.lastUpdate).inDays < 7).toList();

    Manga? continueManga;
    for (final m in list) {
      if (m.progress > 0 && m.progress < 1.0) {
        continueManga = m;
        break;
      }
    }
    continueManga ??= list.first;

    final data = SumiWidgetData(
      newChapterCount: recentUpdates.length,
      continueReading: MangaWidgetItem(
        title: continueManga.title,
        chapterLabel: continueManga.currentChapter > 0
            ? 'Ch. ${continueManga.currentChapter.toStringAsFixed(0)}'
            : 'Reading',
        coverUrl: continueManga.coverUrl ?? '',
        progress: continueManga.progress,
      ),
      updates: list.take(3).map((m) => ChapterWidgetUpdate(
            mangaTitle: m.title,
            chapterLabel: m.currentChapter > 0
                ? 'Ch. ${m.currentChapter.toStringAsFixed(0)}'
                : '',
            timeAgo: _timeAgo(m.lastUpdate),
          )).toList(),
    );
    widgetService.updateAndroidWidgets(data);
  }

  Manga _fromDto(MangaDto dto) {
    final coverFile = dto.coverFileName;
    return Manga(
      id: dto.id,
      title: dto.preferredTitle,
      author: dto.author ?? '',
      coverUrl:
          coverFile != null ? _api.coverUrl(dto.id, coverFile) : null,
      description: dto.preferredDescription,
      genres: dto.genres,
      status: _parseStatus(dto.status),
      currentChapter: dto.lastChapter ?? 0,
      progress: 0,
      lastUpdate: dto.updatedAt ?? DateTime.now(),
    );
  }

  ReadingStatus _parseStatus(String? status) {
    switch (status) {
      case 'ongoing':
        return ReadingStatus.reading;
      case 'completed':
        return ReadingStatus.completed;
      case 'hiatus':
        return ReadingStatus.onHold;
      case 'cancelled':
        return ReadingStatus.dropped;
      default:
        return ReadingStatus.planned;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
