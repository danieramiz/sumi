import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/features/auth/presentation/state/auth_notifier.dart';
import 'package:sumi_app/features/manga/data/providers/manga_repository_provider.dart';
import 'package:sumi_app/features/manga/data/repositories/manga_repository.dart';
import 'package:sumi_app/features/manga/domain/entities/chapter.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';

class MangaState {
  final List<Manga> followedManga;
  final List<Manga> searchResults;
  final bool isLoading;
  final bool isLibraryLoading;
  final String? error;

  const MangaState({
    this.followedManga = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isLibraryLoading = false,
    this.error,
  });

  MangaState copyWith({
    List<Manga>? followedManga,
    List<Manga>? searchResults,
    bool? isLoading,
    bool? isLibraryLoading,
    String? error,
  }) {
    return MangaState(
      followedManga: followedManga ?? this.followedManga,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isLibraryLoading: isLibraryLoading ?? this.isLibraryLoading,
      error: error,
    );
  }
}

class MangaNotifier extends Notifier<MangaState> {
  late final MangaRepository _repository;

  @override
  MangaState build() {
    _repository = ref.read(mangaRepositoryProvider);
    return const MangaState();
  }

  String? get _token => ref.read(authProvider.notifier).accessToken;

  List<Manga> get sortedManga =>
      _repository.sortLibrary(state.followedManga);

  Manga? getMangaById(String id) {
    try {
      return state.followedManga.firstWhere((m) => m.id == id);
    } catch (_) {
      try {
        return state.searchResults.firstWhere((m) => m.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  bool isInLibrary(String id) =>
      state.followedManga.any((m) => m.id == id);

  bool isPinned(String id) => _repository.isPinned(id);

  Future<void> togglePin(String id) async {
    await _repository.togglePin(id);
    state = state.copyWith(followedManga: [...state.followedManga]);
  }

  void refreshSort() {
    state = state.copyWith(followedManga: [...state.followedManga]);
  }

  Future<void> fetchLibrary() async {
    final token = _token;
    if (token == null) return;

    state = state.copyWith(isLibraryLoading: true, error: null);

    try {
      final manga = await _repository.fetchFollowedManga(token);
      state = state.copyWith(
        followedManga: manga,
        isLibraryLoading: false,
      );
      _repository.updateWidgets(manga);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load library: $e',
        isLibraryLoading: false,
      );
      if (state.followedManga.isEmpty) {
        state = state.copyWith(followedManga: _repository.getMockLibrary());
      }
    }
  }

  Future<void> searchManga(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _repository.searchManga(query);
      state = state.copyWith(
        searchResults: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        searchResults: [],
        isLoading: false,
      );
    }
  }

  Future<List<Chapter>> fetchChapters(String mangaId,
      {bool ascending = false, int offset = 0, int limit = 20}) async {
    return _repository.fetchChaptersWithReadStatus(
      mangaId,
      token: _token,
      ascending: ascending,
      offset: offset,
      limit: limit,
    );
  }

  Future<int> fetchTotalChapters(String mangaId) async {
    return _repository.fetchTotalChapters(mangaId, token: _token);
  }

  Future<Manga?> fetchMangaDetails(String id) async {
    return _repository.fetchMangaDetails(id);
  }

  Future<void> addToLibrary(Manga manga) async {
    final token = _token;
    state = state.copyWith(
      followedManga: [manga, ...state.followedManga],
    );
    if (token != null) {
      await _repository.followManga(manga.id, token);
      await _repository.setReadingStatus(manga.id, 'reading', token);
    }
  }

  Future<void> removeFromLibrary(String id) async {
    final token = _token;
    state = state.copyWith(
      followedManga: state.followedManga.where((m) => m.id != id).toList(),
    );
    if (token != null) {
      await _repository.unfollowManga(id, token);
    }
  }

  Future<void> markChapterRead(String mangaId, String chapterId) async {
    final token = _token;
    if (token != null) {
      await _repository.markChapterRead(mangaId, chapterId, token);
    }
  }

  Future<void> markChaptersRead(
      String mangaId, List<String> chapterIds) async {
    final token = _token;
    if (token != null) {
      await _repository.markChaptersRead(mangaId, chapterIds, token);
    }
  }
}

final mangaProvider =
    NotifierProvider<MangaNotifier, MangaState>(MangaNotifier.new);
