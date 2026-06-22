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

  MangaProvider({AuthProvider? authProvider})
      : _authProvider = authProvider {
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

  void addToLibrary(Manga manga) {
    _followedManga.insert(0, manga);
    notifyListeners();
  }

  void removeFromLibrary(String id) {
    _followedManga.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  List<Chapter> getRecentChapters(String mangaId) {
    return mockRecentChapters;
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
          author: '',
          coverUrl:
              dto.coverFileName != null
                  ? _api.coverUrl(dto.id, dto.coverFileName!)
                  : null,
          description: dto.preferredDescription,
          genres: dto.genres,
          status: status,
          currentChapter: dto.lastChapter ?? 0,
          progress: 0,
          lastUpdate: DateTime.now(),
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
          author: '',
          coverUrl:
              dto.coverFileName != null
                  ? _api.coverUrl(dto.id, dto.coverFileName!)
                  : null,
          description: dto.preferredDescription,
          genres: dto.genres,
          status: status,
          currentChapter: dto.lastChapter ?? 0,
          progress: 0,
          lastUpdate: DateTime.now(),
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
        author: '',
        coverUrl:
            dto.coverFileName != null
                ? _api.coverUrl(dto.id, dto.coverFileName!)
                : null,
        description: dto.preferredDescription,
        genres: dto.genres,
        status: status,
        currentChapter: dto.lastChapter ?? 0,
        progress: 0,
        lastUpdate: DateTime.now(),
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
