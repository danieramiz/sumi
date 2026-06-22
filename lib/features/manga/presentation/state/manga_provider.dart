import 'package:flutter/foundation.dart';
import 'package:sumi_app/features/auth/presentation/state/auth_provider.dart';
import 'package:sumi_app/features/manga/data/mock/mock_data.dart';
import 'package:sumi_app/features/manga/data/services/mangadex_service.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/domain/entities/chapter.dart';

class MangaProvider extends ChangeNotifier {
  final MangaDexService _api = MangaDexService();
  final AuthProvider? _authProvider;

  List<Manga> _followedManga = [];
  List<Manga> get followedManga => _followedManga;

  List<Manga> get mangaList => _followedManga;

  List<Manga> _searchResults = [];
  List<Manga> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLibraryLoading = false;
  bool get isLibraryLoading => _isLibraryLoading;

  String? _error;
  String? get error => _error;

  MangaProvider({AuthProvider? authProvider}) : _authProvider = authProvider {
    _followedManga = mockMangaList;
  }

  Manga? getMangaById(String id) {
    try {
      return _followedManga.firstWhere((m) => m.id == id);
    } catch (_) {
      return _searchResults.firstWhere((m) => m.id == id);
    }
  }

  bool isInLibrary(String id) {
    return _followedManga.any((m) => m.id == id);
  }

  Future<void> addToLibrary(Manga manga) async {
    final token = _authProvider?.accessToken;
    _followedManga.insert(0, manga);
    notifyListeners();
    if (token != null) {
      await _api.followManga(manga.id, token);
      await _api.setReadingStatus(manga.id, 'reading', token);
    }
  }

  Future<void> removeFromLibrary(String id) async {
    final token = _authProvider?.accessToken;
    _followedManga.removeWhere((m) => m.id == id);
    notifyListeners();
    if (token != null) {
      await _api.unfollowManga(id, token);
    }
  }

  Future<int> fetchTotalChapters(String mangaId) async {
    try {
      final data = await _api.getMangaAggregate(mangaId);
      return _api.parseTotalChapters(data);
    } catch (_) {
      return 0;
    }
  }

  Future<List<Chapter>> fetchChapters(String mangaId, {bool ascending = false}) async {
    try {
      final dtos = await _api.getChapters(mangaId, limit: 20, ascending: ascending);
      Set<String> readIds = {};
      final token = _authProvider?.accessToken;
      if (token != null) {
        readIds = await _api.getReadChapters(mangaId, token);
      }
      return dtos.map((d) {
        return Chapter(
          id: d.id,
          chapterNumber: d.chapterNumber ?? 0,
          title: d.title,
          publishDate:
              d.publishDate != null ? DateTime.tryParse(d.publishDate!) : null,
          isRead: readIds.contains(d.id),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> fetchLibrary() async {
    final token = _authProvider?.accessToken;
    if (token == null) return;

    _isLibraryLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getFollowedManga(token, limit: 100);
      _followedManga = response.data.map((dto) {
        final status = _parseStatus(dto.status);
        return Manga(
          id: dto.id,
          title: dto.preferredTitle,
          author: dto.author ?? '',
          coverUrl:
              dto.coverFileName != null
                  ? _api.coverUrl(dto.id, dto.coverFileName!)
                  : null,
          description: dto.preferredDescription,
          genres: dto.genres,
          status: status,
          currentChapter: dto.lastChapter ?? 0,
          progress: 0,
          lastUpdate: dto.updatedAt ?? DateTime.now(),
        );
      }).toList();
      if (_followedManga.isEmpty) {
        _followedManga = mockMangaList;
      }
    } catch (e) {
      _error = 'Failed to load library. Showing sample data.';
      _followedManga = mockMangaList;
    }

    _isLibraryLoading = false;
    notifyListeners();
  }

  Future<void> markChapterRead(String mangaId, String chapterId) async {
    final token = _authProvider?.accessToken;
    if (token != null) {
      await _api.markChapterRead(mangaId, chapterId, token);
    }
  }

  Future<void> searchManga(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.searchManga(title: query, limit: 20);
      _searchResults = response.data.map((dto) {
        final status = _parseStatus(dto.status);
        return Manga(
          id: dto.id,
          title: dto.preferredTitle,
          author: dto.author ?? '',
          coverUrl:
              dto.coverFileName != null
                  ? _api.coverUrl(dto.id, dto.coverFileName!)
                  : null,
          description: dto.preferredDescription,
          genres: dto.genres,
          status: status,
          currentChapter: dto.lastChapter ?? 0,
          progress: 0,
          lastUpdate: dto.updatedAt ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Manga?> fetchMangaDetails(String id) async {
    try {
      final dto = await _api.getMangaDetails(id);
      final status = _parseStatus(dto.status);
      return Manga(
        id: dto.id,
        title: dto.preferredTitle,
        author: dto.author ?? '',
        coverUrl:
            dto.coverFileName != null
                ? _api.coverUrl(dto.id, dto.coverFileName!)
                : null,
        description: dto.preferredDescription,
        genres: dto.genres,
        status: status,
        currentChapter: dto.lastChapter ?? 0,
        progress: 0,
        lastUpdate: dto.updatedAt ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
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

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
